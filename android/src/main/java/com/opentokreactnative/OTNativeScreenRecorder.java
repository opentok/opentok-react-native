package com.opentokreactnative;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.media.ImageReader;
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.util.DisplayMetrics;
import androidx.annotation.NonNull;
import com.facebook.react.bridge.*;

public class OTNativeScreenRecorder extends ReactContextBaseJavaModule {
    private static final String TAG = "OTNativeScreenRecorder";

    private MediaProjectionManager projectManager;
    private MediaProjection mediaProjection;
    private VirtualDisplay virtualDisplay;

    private final int REQUEST_CODE = 1010;
    public int screenDensity;
    public int screenWidth;
    public int screenHeight;

    private ImageReader imageReader;
    ImageReader.OnImageAvailableListener listener;

    class MediaProjectionCallback extends MediaProjection.Callback {
        @Override
        public void onStop() {
            super.onStop();
        }
    }

    private ActivityEventListener activityEventListener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {
                try {
                    mediaProjection = projectManager.getMediaProjection(resultCode, data);
                    mediaProjection.registerCallback(new MediaProjectionCallback(), null);
                    virtualDisplay = createVirtualDisplay();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    };

    public OTNativeScreenRecorder(ReactApplicationContext reactContext, ImageReader.OnImageAvailableListener listener) {
        super(reactContext);
        reactContext.addActivityEventListener(activityEventListener);
        this.listener = listener;

        DisplayMetrics metrics = new DisplayMetrics();
        reactContext.getCurrentActivity().getWindowManager().getDefaultDisplay().getMetrics(metrics);
        screenDensity = metrics.densityDpi;
        screenWidth = metrics.widthPixels;
        screenHeight = metrics.heightPixels;
    }

    private VirtualDisplay createVirtualDisplay() {
        if (mediaProjection == null) {
            return null;
        }
        return mediaProjection.createVirtualDisplay(
                TAG,
                screenWidth,
                screenHeight,
                screenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader.getSurface(),
                null,
                null
        );
    }

    public void startRecording() {
        try {
            Intent serviceIntent = new Intent(getCurrentActivity(), OTForegroundService.class);
            getReactApplicationContext().startService(serviceIntent);

            if (projectManager == null) {
                projectManager = (MediaProjectionManager) this.getReactApplicationContext().getSystemService(Context.MEDIA_PROJECTION_SERVICE);
            }

            imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 1);
            imageReader.setOnImageAvailableListener(listener, null);

            Intent captureIntent = projectManager.createScreenCaptureIntent();
            this.getCurrentActivity().startActivityForResult(captureIntent, REQUEST_CODE);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void stopRecording() {
        try {
            if (imageReader != null) {
                imageReader.setOnImageAvailableListener(null, null);
                mediaProjection.stop();
                virtualDisplay = null;
                imageReader = null;
                mediaProjection = null;
            }

            Intent intent = new Intent(getCurrentActivity(), OTForegroundService.class);
            getReactApplicationContext().stopService(intent);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @NonNull
    @Override
    public String getName() {
        return TAG;
    }
}