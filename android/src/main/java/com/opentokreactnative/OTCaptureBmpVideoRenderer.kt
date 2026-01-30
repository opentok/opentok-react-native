package com.opentokreactnative

import android.content.Context
import android.graphics.Bitmap
import android.opengl.GLSurfaceView
import android.view.View
import com.opentok.android.BaseVideoRenderer

/**
 * OTCaptureBmpVideoRenderer
 *
 * OpenTok "renderer" for a Subscriber stream that does two things:
 *
 * (1) Normal display:
 *     - It renders the subscriber video into a GLSurfaceView using OpenGL (via [OTCaptureRenderer]).
 *
 * (2) Frame capture (preview):
 *     - After rendering, it can read back GPU pixels (glReadPixels inside [OTCaptureRenderer])
 *       and emit them as a Bitmap via [onBitmapFrame].
 *
 * Why do we need this?
 * - During screen sharing, OTScreenCapturer uses Canvas to draw the UI into a bitmap.
 * - GLSurfaceView/SurfaceView content does NOT appear in Canvas draw results => black squares.
 * - To avoid black squares, we capture each subscriber's video frames as Bitmaps and pass them
 *   to OTScreenCapturer, which overlays them into the appropriate rectangles.
 *
 * Data flow (numbered):
 * (1) OpenTok SDK receives & decodes remote video and calls [onFrame(frame)].
 * (2) We hand that frame to [OTCaptureRenderer.displayFrame(frame)] (thread-safe store).
 * (3) We call [GLSurfaceView.requestRender()] to schedule a render pass.
 * (4) GLSurfaceView GL-thread calls [OTCaptureRenderer.onDrawFrame()].
 * (5) OTCaptureRenderer draws the frame (YUV->RGB shader) into the GL surface.
 * (6) OTCaptureRenderer optionally renders into an offscreen FBO (Frame Buffer Object) + glReadPixels to produce a Bitmap.
 * (7) OTCaptureRenderer calls our internal callback (Bitmap, w, h).
 * (8) We "re-add" streamId and invoke external [onBitmapFrame(streamId, bmp, w, h)].
 * (9) OTRNSubscriber forwards that bitmap to OTScreenCapturer.updateSubscriberPreview(...)
 *     so it can be drawn as an overlay during screen capture.
 *
 * Threading:
 * - onFrame(...) is called by OpenTok on a non-UI thread (decoder thread).
 * - onDrawFrame(...) runs on the GLSurfaceView GL thread.
 * - onBitmapFrame callback is invoked on the GL thread -> keep it lightweight.
 */
class OTCaptureBmpVideoRenderer(
    private val context: Context,
    private val streamId: String // The Subscriber's streamId (used to identify which preview bitmap belongs to which stream)
) : BaseVideoRenderer() {

    /**
     * The Android View that OpenTok will embed for this renderer.
     *
     * It is a GLSurfaceView:
     * - Video is drawn by the GPU (OpenGL).
     * - Because it's a GL surface, it won't appear in Canvas-based screenshots.
     */
    private val view: GLSurfaceView

    /**
     * The actual OpenGL renderer implementation:
     * - keeps the latest OpenTok Frame
     * - uploads I420 planes to textures
     * - draws with YUV->RGB shader
     * - (optionally) captures a Bitmap via FBO + glReadPixels
     */
    private val renderer: OTCaptureRenderer

    /**
     * Optional callback invoked for captured bitmaps.
     *
     * External signature includes streamId so the caller can map it back to a specific Subscriber tile:
     *   (streamId, bitmap, width, height) -> Unit
     *
     * Internally, OTCaptureRenderer only knows about bitmaps and dimensions, not streamId.
     * So we wrap/unwrap the callback:
     * - set this property -> we create cb: (Bitmap, w, h) and pass to OTCaptureRenderer
     * - when cb is invoked -> we call the external callback adding streamId
     */
    var onBitmapFrame: ((streamId: String, bitmap: Bitmap, width: Int, height: Int) -> Unit)? = null
        set(value) {
            field = value

            // Adapter: OTCaptureRenderer expects (Bitmap, w, h).
            // We inject streamId back in when calling the external callback.
            val cb: ((Bitmap, Int, Int) -> Unit)? =
                if (value == null) null
                else { bmp: Bitmap, w: Int, h: Int ->
                    value.invoke(streamId, bmp, w, h)
                }

            renderer.setOnBitmapFrameListener(cb)
        }

    init {
        // Create the GLSurfaceView that will be used as the Subscriber's video view.
        view = GLSurfaceView(context)

        // Use OpenGL ES 2.0 (required for the shaders in OTCaptureRenderer).
        view.setEGLContextClientVersion(2)

        // Create and attach the OpenGL renderer.
        renderer = OTCaptureRenderer()
        view.setRenderer(renderer)

        // Only render when requestRender() is called.
        // This avoids rendering at display refresh rate when video frames are not changing.
        view.renderMode = GLSurfaceView.RENDERMODE_WHEN_DIRTY
    }

    /**
     * (1) Called by the OpenTok SDK whenever a decoded subscriber video frame is ready.
     * We store it in the GL renderer and request one draw.
     */
    override fun onFrame(frame: Frame) {
        // (2) Store latest frame for the GL thread to consume.
        renderer.displayFrame(frame)

        // (3) Trigger a single GL draw pass.
        view.requestRender()
    }

    /**
     * Receives style changes from OpenTok (fit vs fill) and forwards to our renderer.
     */
    override fun setStyle(key: String, value: String) {
        if (BaseVideoRenderer.STYLE_VIDEO_SCALE == key) {
            when (value) {
                BaseVideoRenderer.STYLE_VIDEO_FIT -> renderer.enableVideoFit(true)
                BaseVideoRenderer.STYLE_VIDEO_FILL -> renderer.enableVideoFit(false)
            }
        }
    }

    /**
     * Called when video is enabled/disabled for this Subscriber.
     * Forwarded to renderer (currently a no-op in OTCaptureRenderer.disableVideo()).
     */
    override fun onVideoPropertiesChanged(videoEnabled: Boolean) {
        renderer.disableVideo(!videoEnabled)
    }

    /**
     * OpenTok asks for the Android view to attach into the layout.
     */
    override fun getView(): View = view

    /**
     * GLSurfaceView lifecycle (pause GL thread).
     */
    override fun onPause() {
        view.onPause()
    }

    /**
     * GLSurfaceView lifecycle (resume GL thread).
     */
    override fun onResume() {
        view.onResume()
    }
}