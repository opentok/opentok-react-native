package com.opentokreactnative

import android.graphics.Bitmap
import android.content.Context
import android.opengl.GLSurfaceView
import android.view.View
import com.opentok.android.BaseVideoRenderer

class OTCaptureBmpVideoRenderer(private val context: Context, private val streamId: String) : BaseVideoRenderer() {

    private val view: GLSurfaceView
    private val renderer: OTCaptureRenderer

    /**
     * Optional callback invoked after a frame has been drawn and read back via glReadPixels.
     * Called on the GL thread (NOT the main thread).
     */
    var onBitmapFrame: ((streamId: String, bitmap: Bitmap, width: Int, height: Int) -> Unit)? = null
        set(value) {
            field = value

            val cb: ((Bitmap, Int, Int) -> Unit)? =
                if (value == null) null
                else { bmp: Bitmap, w: Int, h: Int ->
                    value.invoke(streamId, bmp, w, h)
                }
            renderer.setOnBitmapFrameListener(streamId, cb)
        }

    init {
        view = GLSurfaceView(context)
        view.setEGLContextClientVersion(2)

        renderer = OTCaptureRenderer()
        view.setRenderer(renderer)

        view.renderMode = GLSurfaceView.RENDERMODE_WHEN_DIRTY
    }

    override fun onFrame(frame: Frame) {
        renderer.displayFrame(frame)
        view.requestRender()
    }

    override fun setStyle(key: String, value: String) {
        if (BaseVideoRenderer.STYLE_VIDEO_SCALE == key) {
            when (value) {
                BaseVideoRenderer.STYLE_VIDEO_FIT -> renderer.enableVideoFit(true)
                BaseVideoRenderer.STYLE_VIDEO_FILL -> renderer.enableVideoFit(false)
            }
        }
    }

    override fun onVideoPropertiesChanged(videoEnabled: Boolean) {
        renderer.disableVideo(!videoEnabled)
    }
    
    override fun getView(): View = view

    override fun onPause() {
        view.onPause()
    }

    override fun onResume() {
        view.onResume()
    }
}