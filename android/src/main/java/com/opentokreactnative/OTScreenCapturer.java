package com.opentokreactnative;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Paint;
import android.graphics.Canvas;
import android.graphics.Rect;
import android.os.SystemClock;
import android.os.Handler;
import android.view.View;

import com.opentok.android.BaseVideoCapturer;

import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

/**
 * OTScreenCapturer
 *
 * OpenTok "video capturer" implementation used for screen-sharing.
 *
 * What it captures:
 * - It does NOT use MediaProjection.
 * - Instead it periodically draws the Android view hierarchy into a Bitmap using Canvas:
 *     contentView.draw(canvas)
 *
 * Main issue this solves:
 * - OpenTok Publisher/Subscriber views are GLSurfaceView/SurfaceView-backed most of the time.
 * - Those GL surfaces do NOT appear in Canvas-based rendering -> they show up as black rectangles.
 *
 * How we fix black rectangles:
 * 1) Keep a "previous full-frame screenshot" bitmap (prevFrameBmp) and draw it over the publisher view rect
 *    (drawOverlay(publisherView)).
 *    This makes the publisher tile show a "best effort" image instead of black.
 *
 * 2) For each remote subscriber:
 *    - we capture a small preview bitmap from the subscriber's custom OpenGL renderer
 *      (OTCaptureBmpVideoRenderer/OTCaptureRenderer reads pixels via glReadPixels).
 *    - we store the latest preview per streamId in subscriberPreviews.
 *    - we also store the subscriber's View per streamId in subscriberViews.
 *    - during each capturer tick, we draw those bitmaps on top of the black GL regions
 *      in their exact on-screen rectangles (drawSubscriberPreviews()).
 *
 * Data flow (numbered):
 * (1) startCapture() schedules periodic ticks on main thread via Handler (newFrame Runnable).
 * (2) Each tick:
 *     (2.1) ensure bmp/frame buffers exist and match current contentView size
 *     (2.2) canvas.translate(-scrollX, -scrollY) to match the same coordinate space as the content view
 *     (2.3) contentView.draw(canvas) renders all *normal* views into bmp
 *     (2.4) overlay "missing GL content":
 *           - publisher overlay using prevFrameBmp (drawOverlay)
 *           - subscriber overlays using per-stream preview bitmaps (drawSubscriberPreviews)
 *     (2.5) bmp.getPixels(...) copies bmp -> int[] frame (ARGB pixels)
 *     (2.6) provideIntArrayFrame(...) passes frame to OpenTok as the capturer output
 *     (2.7) prevFrameBmp is updated from frame for the next iteration
 *
 * Threading:
 * - The capture loop (newFrame Runnable) runs on the Handler thread (usually main/UI).
 * - updateSubscriberPreview(...) is called from the subscriber GL thread (OTCaptureRenderer callback).
 *   We store bitmaps inside ConcurrentHashMap and throttle updates to reduce CPU/GC churn.
 */
public class OTScreenCapturer extends BaseVideoCapturer {

    private boolean capturing = false;

    /**
     * The view hierarchy we "screenshot" via Canvas.
     * Usually this is a parent of publisher view (React root/ReactSurfaceView).
     */
    private View contentView;

    /**
     * Publisher view used for special handling:
     * Canvas rendering won't include GL content, so we patch it with drawOverlay(publisherView).
     */
    private View publisherView;

    /**
     * A full-sized bitmap snapshot from the previous tick.
     * Used as a fallback overlay for GL-backed views (publisher tile).
     *
     * Why "previous"?
     * - We need something already in CPU memory that we can draw immediately.
     * - We update it after each tick, so next tick can use it.
     */
    private Bitmap prevFrameBmp;

    // Output frame settings expected by OpenTok
    private int fps = 15;
    private int width = 20;
    private int height = 20;
    private int[] frame;

    // Working bitmap/canvas used for contentView.draw(canvas)
    private Bitmap bmp;
    private Canvas canvas;

    /**
     * Latest preview per subscriber streamId (bitmap + metadata).
     * Populated by updateSubscriberPreview(...) from the subscriber's GL renderer.
     */
    private final ConcurrentHashMap<String, PreviewSlot> subscriberPreviews = new ConcurrentHashMap<>();

    /**
     * Maps streamId -> actual Subscriber view in the layout.
     * Used so we know WHERE to draw the preview bitmap on the captured screenshot.
     */
    private final ConcurrentHashMap<String, View> subscriberViews = new ConcurrentHashMap<>();

    /**
     * Paint used when drawing previews. FILTER_BITMAP_FLAG enables bilinear filtering
     * when scaling the captured preview bitmap into a subscriber view rectangle.
     */
    private final Paint previewPaint = new Paint(Paint.FILTER_BITMAP_FLAG);

    /**
     * Throttle preview updates to reduce CPU cost and memory churn.
     * Called from GL thread; without throttling, glReadPixels + bitmap copies could be heavy.
     */
    private static final long PREVIEW_MIN_INTERVAL_MS = 100; // 10fps

    /**
     * Holds the most recent preview bitmap for a streamId.
     * Volatile fields allow safe publishing across threads with minimal overhead.
     */
    private static final class PreviewSlot {
        volatile Bitmap bitmap;
        volatile int width;
        volatile int height;
        volatile long lastUpdateMs;
    }

    private Handler mHandler = new Handler();

    /**
     * Capture loop runnable. Each run produces one ARGB frame for OpenTok.
     */
    private Runnable newFrame = new Runnable() {
        @Override
        public void run() {
            if (capturing) {
                int width = contentView.getWidth();
                int height = contentView.getHeight();

                // Reallocate buffers if contentView size changed
                if (frame == null ||
                        OTScreenCapturer.this.width != width ||
                        OTScreenCapturer.this.height != height) {

                    OTScreenCapturer.this.width = width;
                    OTScreenCapturer.this.height = height;

                    // Release old bitmaps to avoid keeping large pixel buffers around
                    if (bmp != null) {
                        bmp.recycle();
                        bmp = null;
                    }
                    if (prevFrameBmp != null) {
                        prevFrameBmp.recycle();
                        prevFrameBmp = null;
                    }

                    // bmp: current frame we draw into
                    bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);

                    // prevFrameBmp: previous frame used as overlay for GL-backed publisher view
                    prevFrameBmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);

                    canvas = new Canvas(bmp);
                    frame = new int[width * height];
                }

                // Draw UI hierarchy into bmp
                // We translate by scroll offsets so that view rect calculations (screen coords -> content coords)
                // match the canvas coordinate system.
                canvas.save();
                canvas.translate(-contentView.getScrollX(), -contentView.getScrollY());
                contentView.draw(canvas);

                // Overlay publisher (GL-backed) region with previous frame buffer
                if (prevFrameBmp != null) {
                    drawOverlay(publisherView);
                }

                // Overlay each subscriber region with its latest captured preview bitmap
                drawSubscriberPreviews(canvas);

                canvas.restore();

                // Convert Bitmap -> int[] frame for OpenTok
                // IMPORTANT: getPixels must come BEFORE prevFrameBmp.setPixels(frame),
                // otherwise "frame" still contains old data.
                bmp.getPixels(frame, 0, width, 0, 0, width, height);

                // Update prevFrameBmp for NEXT tick's overlay
                prevFrameBmp.setPixels(frame, 0, width, 0, 0, width, height);

                // Supply the frame to OpenTok (ARGB format)
                provideIntArrayFrame(frame, ARGB, width, height, 0, false);

                // Schedule next tick
                mHandler.postDelayed(newFrame, 1000 / fps);
            }
        }

        /**
         * drawOverlay(View v)
         *
         * Used for GL-backed surfaces (publisher tile).
         * Since GLSurfaceView doesn't appear in Canvas rendering, we paint something over it.
         *
         * Current strategy:
         * - Draw a center-cropped portion of prevFrameBmp into the rectangle occupied by `v`.
         */
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

            // Use float to avoid integer truncation before rounding
            final float x = ((float) viewLoc[0] - contentLoc[0]) - scrollX;
            final float y = ((float) viewLoc[1] - contentLoc[1]) - scrollY;

            final int w = v.getWidth();
            final int h = v.getHeight();
            if (w <= 0 || h <= 0) return;

            // Destination rect where we want to draw within the capture bitmap
            Rect dst = new Rect(Math.round(x), Math.round(y), Math.round(x + w), Math.round(y + h));
            if (dst.width() <= 0 || dst.height() <= 0) return;

            // Clamp dst to the capture frame bounds (avoid drawing outside bitmap)
            Rect frameRect = new Rect(0, 0, OTScreenCapturer.this.width, OTScreenCapturer.this.height);
            if (!dst.intersect(frameRect) || dst.width() <= 0 || dst.height() <= 0) return;

            final int bw = prevFrameBmp.getWidth();
            final int bh = prevFrameBmp.getHeight();
            if (bw <= 0 || bh <= 0) return;

            // Crop source bitmap so the aspect ratio matches the destination rect (no stretching)
            final float srcAspect = (float) bw / (float) bh;
            final float dstAspect = (float) dst.width() / (float) dst.height();

            Rect src;
            if (srcAspect > dstAspect) {
                // Source is wider than dst: crop left/right
                int newW = Math.round(bh * dstAspect);
                int x0 = Math.max(0, (bw - newW) / 2);
                src = new Rect(x0, 0, Math.min(bw, x0 + newW), bh);
            } else {
                // Source is taller than dst: crop top/bottom
                int newH = Math.round(bw / dstAspect);
                int y0 = Math.max(0, (bh - newH) / 2);
                src = new Rect(0, y0, bw, Math.min(bh, y0 + newH));
            }

            canvas.drawBitmap(prevFrameBmp, src, dst, null);
        }

        /**
         * drawSubscriberPreviews(Canvas canvas)
         *
         * Overlays each remote subscriber's captured preview bitmap into its View rectangle.
         *
         * Required inputs:
         * - subscriberPreviews: streamId -> latest captured bitmap
         * - subscriberViews: streamId -> the actual View position/size on screen
         *
         * Behavior:
         * - center-crops the preview to match the view aspect ratio (no stretching)
         * - clamps drawing to the capture bounds
         */
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

                // Convert View's screen coordinates to contentView-relative canvas coordinates
                v.getLocationOnScreen(viewLoc);

                final int left = (viewLoc[0] - contentLoc[0]) - scrollX;
                final int top  = (viewLoc[1] - contentLoc[1]) - scrollY;
                final int right = left + v.getWidth();
                final int bottom = top + v.getHeight();

                Rect dst = new Rect(left, top, right, bottom);
                if (dst.width() <= 0 || dst.height() <= 0) continue;

                // Clamp to capture bounds
                Rect frameRect = new Rect(0, 0, OTScreenCapturer.this.width, OTScreenCapturer.this.height);
                if (!dst.intersect(frameRect) || dst.width() <= 0 || dst.height() <= 0) continue;

                // Compute crop in source bitmap to match dst aspect
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

    /**
     * Associates a subscriber's streamId with its view.
     * Call this when subscriber view is created/destroyed so we know where to overlay the preview.
     */
    public void setSubscriberView(String streamId, View view) {
        if (streamId == null) return;
        if (view == null) {
            subscriberViews.remove(streamId);
        } else {
            subscriberViews.put(streamId, view);
        }
    }

    /**
     * Stores only the latest preview frame per streamId.
     *
     * Called from subscriber GL thread (OTCaptureRenderer callback). Must be:
     * - fast (no heavy work)
     * - thread-safe
     *
     * Implementation details:
     * - per-stream throttle via PREVIEW_MIN_INTERVAL_MS
     * - reuse destination bitmap when possible
     * - copy into our own bitmap so the source can be reused by the renderer
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

        // Per-stream throttle
        if (now - slot.lastUpdateMs < PREVIEW_MIN_INTERVAL_MS) return;

        // Ensure destination bitmap exists and matches incoming frame size
        Bitmap dst = slot.bitmap;
        if (dst == null || dst.isRecycled() || slot.width != w || slot.height != h) {
            if (dst != null && !dst.isRecycled()) {
                dst.recycle();
            }
            dst = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
            slot.bitmap = dst;
            slot.width = w;
            slot.height = h;
        }

        // Copy the pixels into our cached bitmap (snapshot)
        Canvas c = new Canvas(dst);
        c.drawBitmap(src, 0f, 0f, null);

        slot.lastUpdateMs = now;
    }

    public OTScreenCapturer(View view) {
        // Prefer capturing the parent/root so we get the whole app UI around the publisher tile.
        View parentView = (View) view.getParent();
        if (parentView != null) {
            this.contentView = parentView; // React root in many RN setups
        } else {
            this.contentView = view; // Fallback
        }
        this.publisherView = view;
    }

    /**
     * Releases cached subscriber preview bitmaps and clears maps.
     * Called when capture stops to free native bitmap memory.
     */
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
        // OpenTok calls this during capturer setup. No initialization needed here currently.
    }

    @Override
    public int startCapture() {
        capturing = true;

        // Kick off periodic frame generation
        mHandler.postDelayed(newFrame, 1000 / fps);
        return 0;
    }

    @Override
    public int stopCapture() {
        capturing = false;

        // Stop frame loop + free cached previews immediately
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
        // Defensive cleanup: if caller destroys capturer without calling stopCapture()
        capturing = false;
        mHandler.removeCallbacks(newFrame);
        clearSubscriberPreviews();
    }

    @Override
    public void onPause() {
        // No-op: this capturer is view-based; handle pause/resume outside if needed.
    }

    @Override
    public void onResume() {
        // No-op
    }
}