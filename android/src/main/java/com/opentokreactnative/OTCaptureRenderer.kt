package com.opentokreactnative

import kotlin.math.max
import kotlin.math.min

import android.graphics.Bitmap
import android.graphics.Matrix
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.util.Log
import com.opentok.android.BaseVideoRenderer
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.util.concurrent.locks.ReentrantLock
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

class OTCaptureRenderer : GLSurfaceView.Renderer {

    companion object {
        private const val TAG = "MyRenderer"
        // Hardcoded downscale factor: 1=full, 2=half, 4=quarter
        private const val DOWNSCALE = 1
        private const val CAPTURE_LONG_SIDE = 320
    }

    private val frameLock = ReentrantLock()
    private var currentFrame: BaseVideoRenderer.Frame? = null

    private var viewportW: Int = 0
    private var viewportH: Int = 0

    private var onBitmapFrame: ((Bitmap, Int, Int) -> Unit)? = null

    private var readbackBuffer: ByteBuffer? = null
    private var scratchBitmap: Bitmap? = null

    // --- Display (YUV->RGB) shader/program state ---
    private var yuvProgram: Int = 0
    private var yPosLoc: Int = -1
    private var yTexLoc: Int = -1
    private var ySamplerYLoc: Int = -1
    private var ySamplerULoc: Int = -1
    private var ySamplerVLoc: Int = -1

    private var texY: Int = 0
    private var texU: Int = 0
    private var texV: Int = 0

    private var videoW: Int = 0
    private var videoH: Int = 0
    private var yStride: Int = 0
    private var uvStride: Int = 0

    // (OpenTok frames can be mirrored; keep it simple: handle via UV flip)
    @Volatile private var mirrored: Boolean = false
    @Volatile private var videoFit: Boolean = false // true = FIT, false = FILL (crop)

    // --- Capture downscale: FBO + blit program state ---
    private var blitProgram: Int = 0
    private var aPosLoc: Int = -1
    private var aTexLoc: Int = -1
    private var uTexLoc: Int = -1

    private var fboId: Int = 0
    private var fboTexId: Int = 0
    private var fboW: Int = 0
    private var fboH: Int = 0

    private val drawQuadPos: FloatBuffer = ByteBuffer
        .allocateDirect(4 * 2 * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()

    private var quadDirty = true
    private var lastVW = -1
    private var lastVH = -1
    private var lastVidW = -1
    private var lastVidH = -1
    


    private var capFboId: Int = 0
    private var capTexId: Int = 0
    private var capW: Int = 0
    private var capH: Int = 0

    private fun ensureCaptureFbo(w: Int, h: Int) {
        if (capFboId != 0 && capW == w && capH == h) return

        if (capTexId != 0) {
            GLES20.glDeleteTextures(1, intArrayOf(capTexId), 0); capTexId = 0
        }
        if (capFboId != 0) {
            GLES20.glDeleteFramebuffers(1, intArrayOf(capFboId), 0); capFboId = 0
        }

        val fbos = IntArray(1)
        val tex = IntArray(1)
        GLES20.glGenFramebuffers(1, fbos, 0)
        capFboId = fbos[0]
        GLES20.glGenTextures(1, tex, 0)
        capTexId = tex[0]

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, capTexId)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA,
            w, h, 0, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null
        )

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, capFboId)
        GLES20.glFramebufferTexture2D(
            GLES20.GL_FRAMEBUFFER,
            GLES20.GL_COLOR_ATTACHMENT0,
            GLES20.GL_TEXTURE_2D,
            capTexId,
            0
        )

        val status = GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER)
        if (status != GLES20.GL_FRAMEBUFFER_COMPLETE) {
            Log.w(TAG, "Capture FBO not complete, status=$status")
        }

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)

        capW = w
        capH = h
    }

    private fun flipBitmapVertical(src: Bitmap): Bitmap {
        val m = Matrix().apply { preScale(1f, -1f) }
        // Create a new bitmap to avoid mutating the shared scratchBitmap in-place
        return Bitmap.createBitmap(src, 0, 0, src.width, src.height, m, false)
    }

    // Full-screen quad
    private val quadPos: FloatBuffer = ByteBuffer
        .allocateDirect(4 * 2 * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()
        .apply {
            put(floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f))
            position(0)
        }

    // Normal UVs
    private val quadUv: FloatBuffer = ByteBuffer
        .allocateDirect(4 * 2 * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()
        .apply {
            put(floatArrayOf(0f, 1f, 1f, 1f, 0f, 0f, 1f, 0f)) // flipped vertically for GL coords
            position(0)
        }

    // Mirrored UVs (swap left/right)
    private val quadUvMirrored: FloatBuffer = ByteBuffer
        .allocateDirect(4 * 2 * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()
        .apply {
            put(floatArrayOf(1f, 1f, 0f, 1f, 1f, 0f, 0f, 0f))
            position(0)
        }

    fun setOnBitmapFrameListener(streamId: String, cb: ((Bitmap, Int, Int) -> Unit)?) {
        Log.d(TAG, "setOnBitmapFrameListener streamId=$streamId enabled=${cb != null}")
        onBitmapFrame = cb
    }

    fun displayFrame(frame: BaseVideoRenderer.Frame) {
        frameLock.lock()
        try {
            currentFrame?.destroy()
            currentFrame = frame
        } finally {
            frameLock.unlock()
        }
    }

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        // Build YUV shader program (I420: Y + U + V planes)
        yuvProgram = buildProgram(
            // vertex
            """
            attribute vec2 aPos;
            attribute vec2 aTex;
            varying vec2 vTex;
            void main() {
              vTex = aTex;
              gl_Position = vec4(aPos, 0.0, 1.0);
            }
            """.trimIndent(),
            // fragment (BT.601 full-range-ish; adjust if needed)
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

        yPosLoc = GLES20.glGetAttribLocation(yuvProgram, "aPos")
        yTexLoc = GLES20.glGetAttribLocation(yuvProgram, "aTex")
        ySamplerYLoc = GLES20.glGetUniformLocation(yuvProgram, "yTex")
        ySamplerULoc = GLES20.glGetUniformLocation(yuvProgram, "uTex")
        ySamplerVLoc = GLES20.glGetUniformLocation(yuvProgram, "vTexSampler")

        // Build blit program for FBO downscale capture
        blitProgram = buildProgram(
            """
            attribute vec2 aPos;
            attribute vec2 aTex;
            varying vec2 vTex;
            void main() {
              vTex = aTex;
              gl_Position = vec4(aPos, 0.0, 1.0);
            }
            """.trimIndent(),
            """
            precision mediump float;
            varying vec2 vTex;
            uniform sampler2D uTex;
            void main() {
              gl_FragColor = texture2D(uTex, vTex);
            }
            """.trimIndent()
        )
        aPosLoc = GLES20.glGetAttribLocation(blitProgram, "aPos")
        aTexLoc = GLES20.glGetAttribLocation(blitProgram, "aTex")
        uTexLoc = GLES20.glGetUniformLocation(blitProgram, "uTex")

        // Create textures for Y/U/V
        val tex = IntArray(3)
        GLES20.glGenTextures(3, tex, 0)
        texY = tex[0]; texU = tex[1]; texV = tex[2]
        setupPlaneTexture(texY)
        setupPlaneTexture(texU)
        setupPlaneTexture(texV)

        GLES20.glClearColor(0f, 0f, 0f, 1f)
    }

     override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        viewportW = width
        viewportH = height
        GLES20.glViewport(0, 0, width, height)
        quadDirty = true
    }

    // Debug 
    private var lastAspectLogMs: Long = 0
    private var lastReadbackSampleLogMs: Long = 0

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
            // FILL: crop to fill view (your current behavior)
            if (vidAspect > viewAspect) {
                scaleX = vidAspect / viewAspect
                scaleY = 1f
            } else {
                scaleX = 1f
                scaleY = viewAspect / vidAspect
            }
        }
        // Debug log
        val now = android.os.SystemClock.uptimeMillis()
        if (now - lastAspectLogMs > 1000) {
            lastAspectLogMs = now
            Log.d(
                "@Debug MyRendererAspect",
                "video=${videoW}x${videoH} vidAsp=${"%.3f".format(vidAspect)} " +
                    "viewport=${viewportW}x${viewportH} viewAsp=${"%.3f".format(viewAspect)} " +
                    "videoFit=$videoFit scaleX=${"%.3f".format(scaleX)} scaleY=${"%.3f".format(scaleY)}"
            )
        }

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

    override fun onDrawFrame(gl: GL10?) {
      // Grab latest frame reference (no GL calls under lock)
      val frame: BaseVideoRenderer.Frame? = run {
          frameLock.lock()
          try {
              currentFrame
          } finally {
              frameLock.unlock()
          }
      }

      // Clear first
      GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

      if (frame != null) {
          uploadI420(frame)
          updateCropQuadIfNeeded()
          drawI420()
      } else {
          return
      }

      val cb = onBitmapFrame ?: return

        val vw = videoW
        val vh = videoH
        if (vw <= 0 || vh <= 0) return

        val vidAspect = vw.toFloat() / vh.toFloat()
        val longSide = CAPTURE_LONG_SIDE
        val (baseW, baseH) = if (vidAspect >= 1f) {
            val w = longSide
            val h = max(1, (w / vidAspect).toInt())
            w to h
        } else {
            val h = longSide
            val w = max(1, (h * vidAspect).toInt())
            w to h
        }

        val ds = if (DOWNSCALE < 1) 1 else DOWNSCALE
        val outW = max(1, baseW / ds)
        val outH = max(1, baseH / ds)

        // Render the video frame AGAIN into an offscreen FBO at outW/outH using yuvProgram.
        ensureCaptureFbo(outW, outH)
        ensureReadbackBuffers(outW, outH)

        val screenW = viewportW
        val screenH = viewportH

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, capFboId)
        GLES20.glViewport(0, 0, outW, outH)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        // Draw full-frame into capture FBO with the SAME YUV shader.
        // IMPORTANT: use quadPos (no crop) so capture represents the actual video aspect.
        GLES20.glUseProgram(yuvProgram)

        GLES20.glEnableVertexAttribArray(yPosLoc)
        quadPos.position(0)
        GLES20.glVertexAttribPointer(yPosLoc, 2, GLES20.GL_FLOAT, false, 0, quadPos)

        GLES20.glEnableVertexAttribArray(yTexLoc)
        val uvs = if (mirrored) quadUvMirrored else quadUv
        uvs.position(0)
        GLES20.glVertexAttribPointer(yTexLoc, 2, GLES20.GL_FLOAT, false, 0, uvs)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texY)
        GLES20.glUniform1i(ySamplerYLoc, 0)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texU)
        GLES20.glUniform1i(ySamplerULoc, 1)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE2)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texV)
        GLES20.glUniform1i(ySamplerVLoc, 2)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        // Readback
        val buf = readbackBuffer ?: return
        val bmp = scratchBitmap ?: return
        buf.rewind()
        GLES20.glReadPixels(0, 0, outW, outH, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buf)
        buf.rewind()
        bmp.copyPixelsFromBuffer(buf)

        // NEW: flip because glReadPixels is bottom-left origin
        val flipped = flipBitmapVertical(bmp)

        // Restore state for on-screen rendering
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        if (screenW > 0 && screenH > 0) {
            GLES20.glViewport(0, 0, screenW, screenH)
        }
        
        // Debug
        val now2 = android.os.SystemClock.uptimeMillis()
        if (now2 - lastReadbackSampleLogMs > 1000) {
          lastReadbackSampleLogMs = now2
          val sx = (flipped.width / 2).coerceIn(0, flipped.width - 1)
          val sy = (flipped.height / 2).coerceIn(0, flipped.height - 1)
          val px = flipped.getPixel(sx, sy)
          Log.d("@Debug MyRendererReadback", "size=${flipped.width}x${flipped.height} sample=0x${Integer.toHexString(px)}")
      }

        cb.invoke(flipped, outW, outH)
  }

    private fun uploadI420(frame: BaseVideoRenderer.Frame) {
        val w = frameWidth(frame)
        val h = frameHeight(frame)
        val yStr = frameYStride(frame)
        val uvStr = frameUvStride(frame)
        mirrored = frameMirrored(frame)

        val buf = frameBuffer(frame) ?: return

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

        val ySize = yStride * videoH
        val uSize = uvStride * (videoH / 2)

        buf.position(0)
        val yPlane = buf.slice().apply { limit(ySize) }

        buf.position(ySize)
        val uPlane = buf.slice().apply { limit(uSize) }

        buf.position(ySize + uSize)
        val vPlane = buf.slice().apply { limit(uSize) }

        updatePlane(texY, yStride, videoH, yPlane)
        updatePlane(texU, uvStride, videoH / 2, uPlane)
        updatePlane(texV, uvStride, videoH / 2, vPlane)
    }

    private fun frameBuffer(frame: BaseVideoRenderer.Frame): ByteBuffer? =
        // Prefer public method if present
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

    private fun drawI420() {
        GLES20.glUseProgram(yuvProgram)

        GLES20.glEnableVertexAttribArray(yPosLoc)
        quadPos.position(0)
        GLES20.glVertexAttribPointer(yPosLoc, 2, GLES20.GL_FLOAT, false, 0, drawQuadPos)

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

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        // Unbind
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
    }

    private fun setupPlaneTexture(texId: Int) {
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texId)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
    }

    private fun allocPlane(texId: Int, w: Int, h: Int) {
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texId)
        // Using GL_LUMINANCE to store 8-bit plane (works on ES2; deprecated in ES3 but still present on many devices)
        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, w, h, 0, GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, null)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
    }

    private fun updatePlane(texId: Int, w: Int, h: Int, data: ByteBuffer) {
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texId)
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, w, h, GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, data)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
    }

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

    // Kept for compatibility with CaptureBmpVideoRenderer.setStyle / onVideoPropertiesChanged.
    fun enableVideoFit(enable: Boolean) {
      videoFit = enable
      quadDirty = true
    }
    fun disableVideo(disable: Boolean) {}
}