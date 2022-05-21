package com.opentokreactnative;

import android.graphics.Bitmap;
import android.media.Image;
import android.media.ImageReader;
import android.view.View;

import com.facebook.react.bridge.ReactApplicationContext;
import com.opentok.android.BaseVideoCapturer;

import java.nio.ByteBuffer;

public class OTScreenCapturer extends BaseVideoCapturer implements ImageReader.OnImageAvailableListener {
    private boolean capturing = false;
    private ReactApplicationContext reactContext;

    private OTNativeScreenRecorder nativeScreenRecorder;

    public OTScreenCapturer(ReactApplicationContext reactContext) {
        this.reactContext = reactContext;
        this.nativeScreenRecorder = new OTNativeScreenRecorder(reactContext, this);
    }

    @Override
    public void init() {}

    @Override
    public int startCapture() {
        capturing = true;
        nativeScreenRecorder.startRecording();
        return 0;
    }

    @Override
    public int stopCapture() {
        capturing = false;
        nativeScreenRecorder.stopRecording();
        return 0;
    }

    @Override
    public boolean isCaptureStarted() {
        return capturing;
    }

    @Override
    public CaptureSettings getCaptureSettings() {

        CaptureSettings settings = new CaptureSettings();
        settings.fps = 15;
        settings.width = nativeScreenRecorder.screenWidth;
        settings.height = nativeScreenRecorder.screenHeight;
        settings.format = ARGB;
        return settings;
    }

    @Override
    public void destroy() {

    }

    @Override
    public void onPause() {

    }

    @Override
    public void onResume() {

    }

    @Override
    public void onImageAvailable(final ImageReader reader) {
        Image image = null;
        Bitmap bitmap = null;
        try {
            image = reader.acquireNextImage();

            if (image != null) {
                Image.Plane[] planes = image.getPlanes();
                ByteBuffer buffer = planes[0].getBuffer();
                buffer.rewind();

                int pixelStride = planes[0].getPixelStride();
                int rowStride = planes[0].getRowStride();
                int rowPadding = rowStride - pixelStride * reader.getWidth();
                int bitmapWidth = reader.getWidth() + rowPadding / pixelStride;
                bitmap = Bitmap.createBitmap(bitmapWidth, reader.getHeight(), Bitmap.Config.ARGB_8888);
                bitmap.copyPixelsFromBuffer(buffer);

                int width = nativeScreenRecorder.screenWidth;
                int height = nativeScreenRecorder.screenHeight;
                int[] frame = new int[width * height];
                bitmap.getPixels(frame, 0, width, 0, 0, width, height);

                provideIntArrayFrame(frame, ARGB, width, height, 0, false);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (bitmap != null) {
                bitmap.recycle();
            }

            if (image != null) {
                image.close();
            }
        }
    }
}