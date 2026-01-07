package com.opentokreactnative;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.os.Handler;
import android.view.View;

import com.opentok.android.BaseVideoCapturer;

public class OTScreenCapturer extends BaseVideoCapturer {

    private boolean capturing = false;
    private View contentView;
    
    private View publisherView;
    private Bitmap prevFrameBmp;

    private int fps = 15;
    private int width = 20;
    private int height = 20;
    private int[] frame;

    private Bitmap bmp;
    private Canvas canvas;

    private Handler mHandler = new Handler();

    private Runnable newFrame = new Runnable() {
        @Override
        public void run() {
            if (capturing) {
                int width = contentView.getWidth();
                int height = contentView.getHeight();

                if (frame == null ||
                        OTScreenCapturer.this.width != width ||
                        OTScreenCapturer.this.height != height) {

                    OTScreenCapturer.this.width = width;
                    OTScreenCapturer.this.height = height;

                    if (bmp != null) {
                        bmp.recycle();
                        bmp = null;
                    }
                    if (prevFrameBmp != null) {
                        prevFrameBmp.recycle();
                        prevFrameBmp = null;
                    }
                    bmp = Bitmap.createBitmap(width,
                            height, Bitmap.Config.ARGB_8888);

                    prevFrameBmp = Bitmap.createBitmap(width,
                            height, Bitmap.Config.ARGB_8888);

                    canvas = new Canvas(bmp);
                    frame = new int[width * height];
                }
                canvas.save();
                canvas.translate(-contentView.getScrollX(), - contentView.getScrollY());
                contentView.draw(canvas);

                if (prevFrameBmp != null && 
                    publisherView != null &&
                    publisherView.getWidth() > 0 && 
                    publisherView.getHeight() > 0) {
                    
                    float pubX = publisherView.getX();
                    float pubY = publisherView.getY();
                    int pubWidth = publisherView.getWidth();
                    int pubHeight = publisherView.getHeight();
                    
                    canvas.drawBitmap(prevFrameBmp, null, 
                        new android.graphics.RectF(pubX, pubY, pubX + pubWidth, pubY + pubHeight), null);
                }

                bmp.getPixels(frame, 0, width, 0, 0, width, height);

                // Update the previous frame bitmap with the current frame for the next iteration
                prevFrameBmp.setPixels(frame, 0, width, 0, 0, width, height);

                provideIntArrayFrame(frame, ARGB, width, height, 0, false);

                canvas.restore();

                mHandler.postDelayed(newFrame, 1000 / fps);

            }
        }
    };

    public OTScreenCapturer(View view) {
        View parentView = (View) view.getParent();
        if (parentView != null) {
            this.contentView = parentView; // Use ReactSurfaceView in a NewArchitecture
        } else {
            this.contentView = view; // Fallback
        }
        this.publisherView = view;
    }

    @Override
    public void init() {

    }

    @Override
    public int startCapture() {
        capturing = true;

        mHandler.postDelayed(newFrame, 1000 / fps);
        return 0;
    }

    @Override
    public int stopCapture() {
        capturing = false;
        mHandler.removeCallbacks(newFrame);
        return 0;
    }

    @Override
    public boolean isCaptureStarted() {
        return capturing;
    }

    @Override
    public CaptureSettings getCaptureSettings() {

        CaptureSettings settings = new CaptureSettings();
        settings.fps = fps;
        settings.width = width;
        settings.height = height;
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

}