package com.opentokreactnative

import kotlin.math.max
import kotlin.math.min

import android.graphics.Bitmap
import android.graphics.Matrix
import android.opengl.GLES20
import android.opengl.GLSurfaceView

import com.opentok.android.BaseVideoRenderer
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.util.concurrent.locks.ReentrantLock
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

/**
 * OTCaptureRenderer
 *
 * A GLSurfaceView.Renderer that renders OpenTok Subscriber frames (I420/YUV) and can **capture**
 * a downscaled Bitmap for each drawn frame.
 *
 * Why this exists (high-level):
 * - OpenTok Subscriber "view" is typically GL-based (GLSurfaceView/SurfaceView).
 * - Canvas-based screenshots (used by OTScreenCapturer) cannot "see" GL surfaces.
 * - So we render the subscriber in GL as usual, and additionally read pixels back into a Bitmap
 *   (glReadPixels) so OTScreenCapturer can overlay it into the screen-share bitmap.
 *
 * Data flow (numbered):
 * (1) OpenTok SDK calls BaseVideoRenderer.onFrame(frame) (not shown here).
 * (2) OTCaptureBmpVideoRenderer forwards to this class: displayFrame(frame).
 * (3) GLSurfaceView.requestRender() schedules a render pass.
 * (4) GLSurfaceView invokes onDrawFrame() on the GL thread.
 * (5) We upload I420 planes (Y/U/V) from the frame into 3 GL textures.
 * (6) We draw those textures with a YUV->RGB fragment shader onto the visible surface.
 * (7) Capture path: we draw again into an offscreen FBO (smaller size), glReadPixels to RGBA buffer,
 *     copy to a Bitmap, flip vertically, and invoke callback onBitmapFrame(bitmap, w, h).
 *
 * Threading:
 * - displayFrame(...) is called on OpenTok's decoder thread (not GL thread).
 * - onDrawFrame(...) runs on the GLSurfaceView GL thread.
 * - We use frameLock to safely exchange the latest frame between threads.
 */
class OTCaptureRenderer : GLSurfaceView.Renderer {

    companion object {
        /**
         * Downscale factor applied after applying CAPTURE_LONG_SIDE logic.
         * 1 = no extra downscale
         * 2 = half
         * 4 = quarter
         *
         * Bigger value -> less CPU/GPU work for readback, lower bitmap quality.
         */
        private const val DOWNSCALE = 2

        /**
         * Target size (in pixels) for the *long side* of the captured preview bitmap.
         * Example: if video is 16:9 and CAPTURE_LONG_SIDE=320 -> output might be 320x180.
         *
         * This exists to keep readback payload small (glReadPixels is expensive).
         */
        private const val CAPTURE_LONG_SIDE = 320
    }

    // Cross-thread frame handoff (decoder thread -> GL thread)
    private val frameLock = ReentrantLock()

    /**
     * Latest OpenTok frame. Set by displayFrame() on decoder thread, read in onDrawFrame() on GL thread.
     *
     * IMPORTANT: BaseVideoRenderer.Frame often wraps native buffers; we destroy the old frame when replaced.
     */
    private var currentFrame: BaseVideoRenderer.Frame? = null

    // Viewport (actual screen surface size for on-screen rendering)
    private var viewportW: Int = 0
    private var viewportH: Int = 0

    // Capture callback (invoked after we have a Bitmap ready)
    private var onBitmapFrame: ((Bitmap, Int, Int) -> Unit)? = null

    // Readback buffers reused across frames (avoid per-frame allocations)
    private var readbackBuffer: ByteBuffer? = null
    private var scratchBitmap: Bitmap? = null

    // Display shader/program state (I420 -> RGB)
    private var yuvProgram: Int = 0            // GL program for display
    private var yPosLoc: Int = -1              // attribute: vertex position
    private var yTexLoc: Int = -1              // attribute: texture coordinates
    private var ySamplerYLoc: Int = -1         // uniform sampler for Y plane
    private var ySamplerULoc: Int = -1         // uniform sampler for U plane
    private var ySamplerVLoc: Int = -1         // uniform sampler for V plane

    // GL texture IDs storing each I420 plane (stored in GL_LUMINANCE textures)
    private var texY: Int = 0
    private var texU: Int = 0
    private var texV: Int = 0

    // Latest frame "true" dimensions + per-plane strides
    private var videoW: Int = 0
    private var videoH: Int = 0
    private var yStride: Int = 0
    private var uvStride: Int = 0

    /**
     * OpenTok frames can be mirrored (front camera, etc).
     * We handle mirroring by selecting a mirrored UV buffer.
     */
    @Volatile private var mirrored: Boolean = false

    /**
     * Style: FIT vs FILL
     * - FIT: preserve full frame, may letterbox
     * - FILL: fill view, may crop
     *
     * This affects on-screen drawing quad (drawQuadPos buffer).
     */
    @Volatile private var videoFit: Boolean = false // true = FIT, false = FILL (crop)

    // Capture downscale: FBO + blit program state (some is legacy/unused in this snippet)
    private var blitProgram: Int = 0
    private var aPosLoc: Int = -1
    private var aTexLoc: Int = -1
    private var uTexLoc: Int = -1

    /**
     * drawQuadPos is the quad we actually use for on-screen drawing.
     * Its values are updated by updateCropQuadIfNeeded() whenever viewport/video dims change.
     */
    private val drawQuadPos: FloatBuffer = ByteBuffer
        .allocateDirect(4 * 2 * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()

    private var quadDirty = true
    private var lastVW = -1
    private var lastVH = -1
    private var lastVidW = -1
    private var lastVidH = -1

    // Capture-only FBO state (this is what we actually use for preview capture) ---
    private var capFboId: Int = 0        // framebuffer object handle
    private var capTexId: Int = 0        // texture attached to capFboId
    private var capW: Int = 0            // size of cap FBO (capture output width)
    private var capH: Int = 0            // size of cap FBO (capture output height)

    /**
     * Ensure we have an offscreen framebuffer + RGBA texture attachment at size (w x h).
     *
     * This lets us draw the video into a smaller render target before calling glReadPixels,
     * which is significantly faster than reading back the full on-screen surface.
     */
    private fun ensureCaptureFbo(w: Int, h: Int) {
        if (capFboId != 0 && capW == w && capH == h) return

        // Tear down old capture resources if size changes
        if (capTexId != 0) {
            GLES20.glDeleteTextures(1, intArrayOf(capTexId), 0); capTexId = 0
        }
        if (capFboId != 0) {
            GLES20.glDeleteFramebuffers(1, intArrayOf(capFboId), 0); capFboId = 0
        }

        // Create new FBO + texture
        val fbos = IntArray(1)
        val tex = IntArray(1)
        GLES20.glGenFramebuffers(1, fbos, 0)
        capFboId = fbos[0]
        GLES20.glGenTextures(1, tex, 0)
        capTexId = tex[0]

        // Configure capture texture (RGBA)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, capTexId)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)

        // Allocate storage
        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA,
            w, h, 0, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null
        )

        // Attach texture to framebuffer
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, capFboId)
        GLES20.glFramebufferTexture2D(
            GLES20.GL_FRAMEBUFFER,
            GLES20.GL_COLOR_ATTACHMENT0,
            GLES20.GL_TEXTURE_2D,
            capTexId,
            0
        )

        // Validate FBO
        @Suppress("UNUSED_VARIABLE")
        val status = GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER)

        // Unbind
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)

        capW = w
        capH = h
    }

    /**
     * glReadPixels reads framebuffer with (0,0) at bottom-left.
     * Android Bitmaps assume (0,0) at top-left.
     * So the copied bitmap appears upside-down unless we flip.
     */
    private fun flipBitmapVertical(src: Bitmap): Bitmap {
        val m = Matrix().apply { preScale(1f, -1f) }
        return Bitmap.createBitmap(src, 0, 0, src.width, src.height, m, false)
    }

    // Full-screen quad positions (covers full render target)
    private val quadPos: FloatBuffer = ByteBuffer
        .allocateDirect(4 * 2 * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()
        .apply {
            put(floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f))
            position(0)
        }

    /**
     * UVs for sampling the I420 textures.
     * Values are arranged so the video appears correct in OpenGL coordinate system.
     */
    private val quadUv: FloatBuffer = ByteBuffer
        .allocateDirect(4 * 2 * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()
        .apply {
            // flipped vertically to match GL coords
            put(floatArrayOf(0f, 1f, 1f, 1f, 0f, 0f, 1f, 0f))
            position(0)
        }

    /**
     * Mirrored UVs: swap left/right.
     * Used when OpenTok reports frame mirrored.
     */
    private val quadUvMirrored: FloatBuffer = ByteBuffer
        .allocateDirect(4 * 2 * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()
        .apply {
            put(floatArrayOf(1f, 1f, 0f, 1f, 1f, 0f, 0f, 0f))
            position(0)
        }

    /**
     * Set a capture callback. When set, onDrawFrame() will emit a Bitmap each frame.
     */
    fun setOnBitmapFrameListener(cb: ((Bitmap, Int, Int) -> Unit)?) {
        onBitmapFrame = cb
    }

    /**
     * Called from decoder thread (via OTCaptureBmpVideoRenderer.onFrame()).
     * Stores the latest frame for the GL thread to render.
     */
    fun displayFrame(frame: BaseVideoRenderer.Frame) {
        frameLock.lock()
        try {
            // Replace existing frame and free native resources tied to the old one.
            currentFrame?.destroy()
            currentFrame = frame
        } finally {
            frameLock.unlock()
        }
    }

    /**
     * GL initialization.
     * We build:
     * - yuvProgram: YUV->RGB shader program for drawing OpenTok I420 frames.
     * - blitProgram: a simple texture blit program (currently not used in capture path).
     * - plane textures: texY/texU/texV to store I420 planes.
     */
    override fun onSurfaceCreated(_: GL10?, config: EGLConfig?) {
        // Build YUV shader program (I420: Y + U + V planes)
        yuvProgram = buildProgram(
            // vertex shader
            """
            attribute vec2 aPos;
            attribute vec2 aTex;
            varying vec2 vTex;
            void main() {
              vTex = aTex;
              gl_Position = vec4(aPos, 0.0, 1.0);
            }
            """.trimIndent(),
            // fragment shader (simple BT.601 style conversion; may need tuning for your content)
            """
            precision mediump float;
            varying vec2 vTex;
            uniform sampler2D yTex;
            uniform sampler2D uTex;
            uniform sampler2D vTexSampler;

            void main() {
              float y = texture2D(yTex, vTex).r;
              float u = texture2D(uTex, vTex).r - 0.5;
              float v = texture2D(vTexSampler, vTex).r - 0.5;

              float r = y + 1.402 * v;
              float g = y - 0.344136 * u - 0.714136 * v;
              float b = y + 1.772 * u;

              gl_FragColor = vec4(r, g, b, 1.0);
            }
            """.trimIndent()
        )

        // Resolve shader locations
        yPosLoc = GLES20.glGetAttribLocation(yuvProgram, "aPos")
        yTexLoc = GLES20.glGetAttribLocation(yuvProgram, "aTex")
        ySamplerYLoc = GLES20.glGetUniformLocation(yuvProgram, "yTex")
        ySamplerULoc = GLES20.glGetUniformLocation(yuvProgram, "uTex")
        ySamplerVLoc = GLES20.glGetUniformLocation(yuvProgram, "vTexSampler")

        // Create textures for Y/U/V planes
        val tex = IntArray(3)
        GLES20.glGenTextures(3, tex, 0)
        texY = tex[0]; texU = tex[1]; texV = tex[2]
        setupPlaneTexture(texY)
        setupPlaneTexture(texU)
        setupPlaneTexture(texV)

        // Default clear color (black)
        GLES20.glClearColor(0f, 0f, 0f, 1f)
    }

    /**
     * Called when view/surface size changes.
     */
    override fun onSurfaceChanged(_: GL10?, width: Int, height: Int) {
        viewportW = width
        viewportH = height
        GLES20.glViewport(0, 0, width, height)
        quadDirty = true
    }

    /**
     * Recompute the on-screen quad (drawQuadPos) based on:
     * - the view aspect ratio (viewportW/viewportH)
     * - the video aspect ratio (videoW/videoH)
     * - the selected mode (FIT vs FILL)
     *
     * This changes only the on-screen *geometry*; it does not affect capture output,
     * because capture draws a full quad (quadPos) by design.
     */
    private fun updateCropQuadIfNeeded() {
        if (viewportW <= 0 || viewportH <= 0 || videoW <= 0 || videoH <= 0) return

        if (!quadDirty &&
            lastVW == viewportW &&
            lastVH == viewportH &&
            lastVidW == videoW &&
            lastVidH == videoH
        ) return

        val viewAspect = viewportW.toFloat() / viewportH.toFloat()
        val vidAspect = videoW.toFloat() / videoH.toFloat()

        val scaleX: Float
        val scaleY: Float

        if (videoFit) {
            // FIT: show whole video, letterbox if needed (no crop)
            if (vidAspect > viewAspect) {
                // video wider -> reduce Y
                scaleX = 1f
                scaleY = viewAspect / vidAspect
            } else {
                // video taller -> reduce X
                scaleX = vidAspect / viewAspect
                scaleY = 1f
            }
        } else {
            // FILL: crop to fill view
            if (vidAspect > viewAspect) {
                scaleX = vidAspect / viewAspect
                scaleY = 1f
            } else {
                scaleX = 1f
                scaleY = viewAspect / vidAspect
            }
        }

        // Update the quad geometry used for on-screen draw
        drawQuadPos.position(0)
        drawQuadPos.put(-scaleX); drawQuadPos.put(-scaleY)
        drawQuadPos.put( scaleX); drawQuadPos.put(-scaleY)
        drawQuadPos.put(-scaleX); drawQuadPos.put( scaleY)
        drawQuadPos.put( scaleX); drawQuadPos.put( scaleY)
        drawQuadPos.position(0)

        lastVW = viewportW
        lastVH = viewportH
        lastVidW = videoW
        lastVidH = videoH
        quadDirty = false
    }

    /**
     * Main draw entry point (GL thread).
     *
     * This does:
     * - On-screen rendering (full size): uploadI420 + drawI420
     * - Offscreen capture rendering (small size): draw into capFboId + glReadPixels + callback
     */
    override fun onDrawFrame(_: GL10?) {
        // Grab latest frame reference (do NOT do GL calls under lock)
        val frame: BaseVideoRenderer.Frame? = run {
            frameLock.lock()
            try {
                currentFrame
            } finally {
                frameLock.unlock()
            }
        }

        // Clear the on-screen surface
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        // Render the visible subscriber video
        if (frame != null) {
            // Upload Y/U/V planes into textures
            uploadI420(frame)

            // Update quad geometry depending on FIT/FILL + aspect ratios
            updateCropQuadIfNeeded()

            // Draw to screen using yuvProgram (I420 -> RGB)
            drawI420()
        } else {
            return
        }

        // If no capture listener, stop here (rendering still works)
        val cb = onBitmapFrame ?: return

        // Decide capture output size, based on the video's aspect ratio
        val vw = videoW
        val vh = videoH
        if (vw <= 0 || vh <= 0) return

        val vidAspect = vw.toFloat() / vh.toFloat()
        val longSide = CAPTURE_LONG_SIDE

        // Compute base output size that preserves aspect ratio with fixed long edge
        val (baseW, baseH) = if (vidAspect >= 1f) {
            val w = longSide
            val h = max(1, (w / vidAspect).toInt())
            w to h
        } else {
            val h = longSide
            val w = max(1, (h * vidAspect).toInt())
            w to h
        }

        // Apply extra integer downscale if configured
        val ds = if (DOWNSCALE < 1) 1 else DOWNSCALE
        val outW = max(1, baseW / ds)
        val outH = max(1, baseH / ds)

        // Render AGAIN into an offscreen framebuffer at outW/outH
        // Why render again?
        // - Reading back the full on-screen surface is expensive.
        // - Offscreen FBO is smaller -> much faster readback.
        ensureCaptureFbo(outW, outH)
        ensureReadbackBuffers(outW, outH)

        // Save current on-screen viewport so we can restore it after capture
        val screenW = viewportW
        val screenH = viewportH

        // Bind capture FBO and set its small viewport
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, capFboId)
        GLES20.glViewport(0, 0, outW, outH)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        // Draw full-frame into capture FBO with the SAME YUV shader.
        // IMPORTANT:
        // - For capture we deliberately use quadPos (no crop) to preserve the entire video frame.
        // - This means capture preview represents the "raw" video content, not the cropped on-screen view.
        GLES20.glUseProgram(yuvProgram)

        GLES20.glEnableVertexAttribArray(yPosLoc)
        quadPos.position(0)
        GLES20.glVertexAttribPointer(yPosLoc, 2, GLES20.GL_FLOAT, false, 0, quadPos)

        GLES20.glEnableVertexAttribArray(yTexLoc)
        val uvs = if (mirrored) quadUvMirrored else quadUv
        uvs.position(0)
        GLES20.glVertexAttribPointer(yTexLoc, 2, GLES20.GL_FLOAT, false, 0, uvs)

        // Bind plane textures Y/U/V to texture units 0/1/2
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texY)
        GLES20.glUniform1i(ySamplerYLoc, 0)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texU)
        GLES20.glUniform1i(ySamplerULoc, 1)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE2)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texV)
        GLES20.glUniform1i(ySamplerVLoc, 2)

        // Draw the capture quad
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        // Read pixels from the capture framebuffer
        val buf = readbackBuffer ?: return
        val bmp = scratchBitmap ?: return

        buf.rewind()
        GLES20.glReadPixels(0, 0, outW, outH, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buf)
        buf.rewind()
        bmp.copyPixelsFromBuffer(buf)

        // Fix vertical orientation (glReadPixels origin mismatch)
        val flipped = flipBitmapVertical(bmp)

        // Restore on-screen framebuffer + viewport so future draws are correct
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        if (screenW > 0 && screenH > 0) {
            GLES20.glViewport(0, 0, screenW, screenH)
        }

        // Emit the captured preview bitmap (GL thread)
        cb.invoke(flipped, outW, outH)
    }

    /**
     * Upload I420 planes from the OpenTok frame into GL textures.
     *
     * OpenTok's I420 buffer layout is assumed to be a single ByteBuffer with:
     *  - Y plane first: yStride * height bytes
     *  - U plane next: uvStride * (height/2) bytes
     *  - V plane last: uvStride * (height/2) bytes
     *
     * Note: Strides matter. We allocate textures using stride widths so TexSubImage aligns correctly.
     */
    private fun uploadI420(frame: BaseVideoRenderer.Frame) {
        val w = frameWidth(frame)
        val h = frameHeight(frame)
        val yStr = frameYStride(frame)
        val uvStr = frameUvStride(frame)
        mirrored = frameMirrored(frame)

        val buf = frameBuffer(frame) ?: return

        // If size/stride changed, reallocate plane textures
        if (videoW != w || videoH != h || yStride != yStr || uvStride != uvStr) {
            videoW = w
            videoH = h
            yStride = yStr
            uvStride = uvStr

            // Allocate texture storage sized by strides (important!)
            allocPlane(texY, yStride, videoH)
            allocPlane(texU, uvStride, videoH / 2)
            allocPlane(texV, uvStride, videoH / 2)
        }

        // Slice the "packed" I420 buffer into three plane buffers
        val ySize = yStride * videoH
        val uSize = uvStride * (videoH / 2)

        buf.position(0)
        val yPlane = buf.slice().apply { limit(ySize) }

        buf.position(ySize)
        val uPlane = buf.slice().apply { limit(uSize) }

        buf.position(ySize + uSize)
        val vPlane = buf.slice().apply { limit(uSize) }

        // Upload each plane into its texture
        updatePlane(texY, yStride, videoH, yPlane)
        updatePlane(texU, uvStride, videoH / 2, uPlane)
        updatePlane(texV, uvStride, videoH / 2, vPlane)
    }

    /**
     * Reflection-based accessors: OpenTok's Frame API differs across versions.
     * These helpers try multiple method names / fields.
     */
    private fun frameBuffer(frame: BaseVideoRenderer.Frame): ByteBuffer? =
        runCatching { frame.javaClass.getMethod("getBuffer").invoke(frame) as ByteBuffer }.getOrNull()
            ?: runCatching { frame.javaClass.getDeclaredField("buffer").apply { isAccessible = true }.get(frame) as ByteBuffer }.getOrNull()

    private fun frameWidth(frame: BaseVideoRenderer.Frame): Int =
        runCatching { frame.javaClass.getMethod("getWidth").invoke(frame) as Int }.getOrElse { videoW }

    private fun frameHeight(frame: BaseVideoRenderer.Frame): Int =
        runCatching { frame.javaClass.getMethod("getHeight").invoke(frame) as Int }.getOrElse { videoH }

    private fun frameYStride(frame: BaseVideoRenderer.Frame): Int =
        runCatching { frame.javaClass.getMethod("getYStride").invoke(frame) as Int }
            .recoverCatching { frame.javaClass.getMethod("getYstride").invoke(frame) as Int }
            .getOrElse { frameWidth(frame) } // fallback: assume tightly packed

    private fun frameUvStride(frame: BaseVideoRenderer.Frame): Int =
        runCatching { frame.javaClass.getMethod("getUvStride").invoke(frame) as Int }
            .recoverCatching { frame.javaClass.getMethod("getUVStride").invoke(frame) as Int }
            .recoverCatching { frame.javaClass.getMethod("getUvstride").invoke(frame) as Int }
            .getOrElse { frameWidth(frame) / 2 }

    private fun frameMirrored(frame: BaseVideoRenderer.Frame): Boolean =
        runCatching { frame.javaClass.getMethod("isMirrored").invoke(frame) as Boolean }
            .recoverCatching { frame.javaClass.getMethod("getMirrored").invoke(frame) as Boolean }
            .getOrElse { false }

    /**
     * Draw the currently uploaded YUV textures to the currently bound framebuffer.
     *
     * IMPORTANT: This function uses drawQuadPos (FIT/FILL crop). For capture,
     * onDrawFrame explicitly draws using quadPos (no crop) using the same program.
     */
    private fun drawI420() {
        GLES20.glUseProgram(yuvProgram)

        // Geometry (positions)
        GLES20.glEnableVertexAttribArray(yPosLoc)
        quadPos.position(0)
        GLES20.glVertexAttribPointer(yPosLoc, 2, GLES20.GL_FLOAT, false, 0, drawQuadPos)

        // UVs (mirrored or not)
        GLES20.glEnableVertexAttribArray(yTexLoc)
        val uvs = if (mirrored) quadUvMirrored else quadUv
        uvs.position(0)
        GLES20.glVertexAttribPointer(yTexLoc, 2, GLES20.GL_FLOAT, false, 0, uvs)

        // Bind planes to texture units 0/1/2
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texY)
        GLES20.glUniform1i(ySamplerYLoc, 0)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texU)
        GLES20.glUniform1i(ySamplerULoc, 1)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE2)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texV)
        GLES20.glUniform1i(ySamplerVLoc, 2)

        // Draw quad
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        // Unbind to leave clean GL state
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
    }

    /**
     * Configure sampling + wrap mode for a plane texture.
     */
    private fun setupPlaneTexture(texId: Int) {
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texId)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
    }

    /**
     * Allocate texture storage for a plane.
     * Uses GL_LUMINANCE to store 8-bit plane values (good enough for ES2 pipeline).
     */
    private fun allocPlane(texId: Int, w: Int, h: Int) {
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texId)
        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D,
            0,
            GLES20.GL_LUMINANCE,
            w,
            h,
            0,
            GLES20.GL_LUMINANCE,
            GLES20.GL_UNSIGNED_BYTE,
            null
        )
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
    }

    /**
     * Update plane texture content with new frame plane bytes.
     */
    private fun updatePlane(texId: Int, w: Int, h: Int, data: ByteBuffer) {
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texId)
        GLES20.glTexSubImage2D(
            GLES20.GL_TEXTURE_2D,
            0,
            0,
            0,
            w,
            h,
            GLES20.GL_LUMINANCE,
            GLES20.GL_UNSIGNED_BYTE,
            data
        )
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
    }

    /**
     * Allocate/reuse readback buffers sized for (w x h).
     * - readbackBuffer: RGBA bytes from glReadPixels
     * - scratchBitmap: destination Bitmap to copy pixels into
     */
    private fun ensureReadbackBuffers(w: Int, h: Int) {
        val needed = w * h * 4
        if (readbackBuffer == null || readbackBuffer!!.capacity() != needed) {
            readbackBuffer = ByteBuffer.allocateDirect(needed).order(ByteOrder.nativeOrder())
        }
        if (scratchBitmap == null || scratchBitmap!!.width != w || scratchBitmap!!.height != h) {
            scratchBitmap?.recycle()
            scratchBitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        }
    }

    /**
     * Utility: compile + link shaders into a GL program.
     */
    private fun buildProgram(vs: String, fs: String): Int {
        val v = compileShader(GLES20.GL_VERTEX_SHADER, vs)
        val f = compileShader(GLES20.GL_FRAGMENT_SHADER, fs)
        val p = GLES20.glCreateProgram()
        GLES20.glAttachShader(p, v)
        GLES20.glAttachShader(p, f)
        GLES20.glLinkProgram(p)

        val link = IntArray(1)
        GLES20.glGetProgramiv(p, GLES20.GL_LINK_STATUS, link, 0)
        if (link[0] == 0) {
            val log = GLES20.glGetProgramInfoLog(p)
            GLES20.glDeleteProgram(p)
            throw RuntimeException("Program link failed: $log")
        }

        GLES20.glDeleteShader(v)
        GLES20.glDeleteShader(f)
        return p
    }

    /**
     * Utility: compile a single shader.
     */
    private fun compileShader(type: Int, src: String): Int {
        val s = GLES20.glCreateShader(type)
        GLES20.glShaderSource(s, src)
        GLES20.glCompileShader(s)
        val ok = IntArray(1)
        GLES20.glGetShaderiv(s, GLES20.GL_COMPILE_STATUS, ok, 0)
        if (ok[0] == 0) {
            val log = GLES20.glGetShaderInfoLog(s)
            GLES20.glDeleteShader(s)
            throw RuntimeException("Shader compile failed: $log")
        }
        return s
    }

    /**
     * Fit/fill control called by BaseVideoRenderer.setStyle in OTCaptureBmpVideoRenderer.
     * Marks quad as dirty so it recomputes on next frame.
     */
    fun enableVideoFit(enable: Boolean) {
        videoFit = enable
        quadDirty = true
    }

    /**
     * Video enable/disable callback. Not implemented (no-op).
     */
    fun disableVideo(disable: Boolean) {}
}