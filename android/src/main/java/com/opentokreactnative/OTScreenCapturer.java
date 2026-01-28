package com.opentokreactnative;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Paint;
import android.graphics.Canvas;
import android.graphics.RectF;
import android.graphics.Rect;
import android.os.SystemClock;
import android.os.Handler;
import android.view.View;

import com.opentok.android.BaseVideoCapturer;

import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

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

    // Keep only the latest preview per streamId
    private final ConcurrentHashMap<String, PreviewSlot> subscriberPreviews = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, View> subscriberViews = new ConcurrentHashMap<>();

    private final Paint previewPaint = new Paint(Paint.FILTER_BITMAP_FLAG);

    // Throttle copying previews to reduce CPU/GC cost (adjust as needed)
    private static final long PREVIEW_MIN_INTERVAL_MS = 100; // 10fps

    private static final class PreviewSlot {
        volatile Bitmap bitmap;
        volatile int width;
        volatile int height;
        volatile long lastUpdateMs;
    }

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

                if (prevFrameBmp != null) {
                    drawOverlay(publisherView);
                }
                drawSubscriberPreviews(canvas);
                canvas.restore();
                // Update the previous frame bitmap with the current frame for the next iteration
                prevFrameBmp.setPixels(frame, 0, width, 0, 0, width, height);
                
                bmp.getPixels(frame, 0, width, 0, 0, width, height);
                provideIntArrayFrame(frame, ARGB, width, height, 0, false);

                mHandler.postDelayed(newFrame, 1000 / fps);

            }
        }

        private void drawOverlay(View v) {
            if (v == null || prevFrameBmp == null || canvas == null) return;
            if (v.getWidth() <= 0 || v.getHeight() <= 0) return;

            int[] viewLoc = new int[2];
            int[] contentLoc = new int[2];
            v.getLocationOnScreen(viewLoc);
            contentView.getLocationOnScreen(contentLoc);

            // Match coordinate space used for contentView.draw(canvas)
            final int scrollX = contentView.getScrollX();
            final int scrollY = contentView.getScrollY();

            final float x = ((float) viewLoc[0] - contentLoc[0]) - scrollX;
            final float y = ((float) viewLoc[1] - contentLoc[1]) - scrollY;
            final int w = v.getWidth();
            final int h = v.getHeight();
            if (w <= 0 || h <= 0) return;

            Rect dst = new Rect(Math.round(x), Math.round(y), Math.round(x + w), Math.round(y + h));
            if (dst.width() <= 0 || dst.height() <= 0) return;

            // Clamp to capture frame bounds (prevents partial/out-of-bounds weirdness)
            Rect frameRect = new Rect(0, 0, OTScreenCapturer.this.width, OTScreenCapturer.this.height);
            if (!dst.intersect(frameRect) || dst.width() <= 0 || dst.height() <= 0) return;

            final int bw = prevFrameBmp.getWidth();
            final int bh = prevFrameBmp.getHeight();
            if (bw <= 0 || bh <= 0) return;

            final float srcAspect = (float) bw / (float) bh;
            final float dstAspect = (float) dst.width() / (float) dst.height();

            // Center-crop the prevFrameBmp to match dst aspect (avoids squish)
            Rect src;
            if (srcAspect > dstAspect) {
                int newW = Math.round(bh * dstAspect);
                int x0 = Math.max(0, (bw - newW) / 2);
                src = new Rect(x0, 0, Math.min(bw, x0 + newW), bh);
            } else {
                int newH = Math.round(bw / dstAspect);
                int y0 = Math.max(0, (bh - newH) / 2);
                src = new Rect(0, y0, bw, Math.min(bh, y0 + newH));
            }

            canvas.drawBitmap(prevFrameBmp, src, dst, null);
        }

        // Call this from your capture loop after contentView.draw(canvas)
        private void drawSubscriberPreviews(Canvas canvas) {
            int[] viewLoc = new int[2];
            int[] contentLoc = new int[2];
            contentView.getLocationOnScreen(contentLoc);

            final int scrollX = contentView.getScrollX();
            final int scrollY = contentView.getScrollY();

            for (Map.Entry<String, PreviewSlot> e : subscriberPreviews.entrySet()) {
                final String streamId = e.getKey();
                final PreviewSlot slot = e.getValue();


                final Bitmap b = (slot != null) ? slot.bitmap : null;
                if (b == null || b.isRecycled()) continue;

                final View v = subscriberViews.get(streamId);
                if (v == null || v.getWidth() <= 0 || v.getHeight() <= 0) continue;
                
                v.getLocationOnScreen(viewLoc);

                // Position relative to contentView, then compensate for the translate(-scrollX, -scrollY)
                final int left = (viewLoc[0] - contentLoc[0]) - scrollX;
                final int top  = (viewLoc[1] - contentLoc[1]) - scrollY;
                final int right = left + v.getWidth();
                final int bottom = top + v.getHeight();

                Rect dst = new Rect(left, top, right, bottom);
                if (dst.width() <= 0 || dst.height() <= 0) continue;

                // Clamp to capture bounds
                Rect frameRect = new Rect(0, 0, OTScreenCapturer.this.width, OTScreenCapturer.this.height);
                if (!dst.intersect(frameRect) || dst.width() <= 0 || dst.height() <= 0) continue;

                final int bw = b.getWidth();
                final int bh = b.getHeight();
                if (bw <= 0 || bh <= 0) continue;

                final float srcAspect = (float) bw / (float) bh;
                final float dstAspect = (float) dst.width() / (float) dst.height();

                Rect src;
                if (srcAspect > dstAspect) {
                    int newW = Math.round(bh * dstAspect);
                    int x0 = Math.max(0, (bw - newW) / 2);
                    src = new Rect(x0, 0, Math.min(bw, x0 + newW), bh);
                } else {
                    int newH = Math.round(bw / dstAspect);
                    int y0 = Math.max(0, (bh - newH) / 2);
                    src = new Rect(0, y0, bw, Math.min(bh, y0 + newH));
                }

                canvas.drawBitmap(b, src, dst, previewPaint);
            }
        }
    };

    public void setSubscriberView(String streamId, View view) {
        if (streamId == null) return;
        if (view == null) {
            subscriberViews.remove(streamId);
        } else {
            subscriberViews.put(streamId, view);
        }
    }

    /**
    * Store only the latest preview frame per streamId.
    * Called from subscriber GL thread -> keep it lightweight and thread-safe.
    */
    public void updateSubscriberPreview(String streamId, Bitmap src, int w, int h) {
        if (streamId == null || src == null) return;
        if (w <= 0 || h <= 0) return;
        if (src.isRecycled()) return;

        final long now = SystemClock.uptimeMillis();

        PreviewSlot slot = subscriberPreviews.get(streamId);
        if (slot == null) {
            slot = new PreviewSlot();
            PreviewSlot prev = subscriberPreviews.putIfAbsent(streamId, slot);
            if (prev != null) slot = prev;
        }

        // Simple per-stream throttle
        if (now - slot.lastUpdateMs < PREVIEW_MIN_INTERVAL_MS) return;

        // Ensure destination bitmap exists and matches size.
        Bitmap dst = slot.bitmap;
        if (dst == null || dst.isRecycled() || slot.width != w || slot.height != h) {
            // Release old bitmap if any
            if (dst != null && !dst.isRecycled()) {
                dst.recycle();
            }
            dst = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
            slot.bitmap = dst;
            slot.width = w;
            slot.height = h;
        }

        // Copy pixels safely: create an immutable snapshot.
        Canvas c = new Canvas(dst);
        c.drawBitmap(src, 0f, 0f, null);

        slot.lastUpdateMs = now;
    }

    public OTScreenCapturer(View view) {
        View parentView = (View) view.getParent();
        if (parentView != null) {
            this.contentView = parentView; // Use ReactSurfaceView in a NewArchitecture
        } else {
            this.contentView = view; // Fallback
        }
        this.publisherView = view;
    }

    // Release cached preview bitmaps and clear maps
    private void clearSubscriberPreviews() {
        for (PreviewSlot slot : subscriberPreviews.values()) {
            if (slot == null) continue;
            Bitmap b = slot.bitmap;
            slot.bitmap = null;
            if (b != null && !b.isRecycled()) {
                b.recycle();
            }
        }
        subscriberPreviews.clear();
        subscriberViews.clear();
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
        clearSubscriberPreviews();
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