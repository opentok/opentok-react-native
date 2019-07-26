package com.opentokreactnative;

import android.opengl.GLSurfaceView;
import android.view.Gravity;
import android.widget.FrameLayout;

import com.facebook.react.uimanager.ThemedReactContext;
import com.opentok.android.BaseVideoRenderer;
import com.opentok.android.Subscriber;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Created by manik on 1/10/18.
 */

public class OTSubscriberLayout extends FrameLayout{

    public OTRN sharedState;

    public OTSubscriberLayout(ThemedReactContext reactContext) {

        super(reactContext);
        sharedState = OTRN.getSharedState();
    }

    public void createSubscriberView(String streamId) {

        ConcurrentHashMap<String, Subscriber> mSubscribers = sharedState.getSubscribers();
        ConcurrentHashMap<String, String> androidOnTopMap = sharedState.getAndroidOnTopMap();
        ConcurrentHashMap<String, String> androidZOrderMap = sharedState.getAndroidZOrderMap();
        Subscriber mSubscriber = mSubscribers.get(streamId);
        FrameLayout mSubscriberViewContainer = new FrameLayout(getContext());
        String pubOrSub = "";
        String zOrder = "";
        if (mSubscriber != null) {
            if (mSubscriber.getSession() != null) {
                if (androidOnTopMap.get(mSubscriber.getSession().getSessionId()) != null) {
                    pubOrSub = androidOnTopMap.get(mSubscriber.getSession().getSessionId());
                }
                if (androidZOrderMap.get(mSubscriber.getSession().getSessionId()) != null) {
                    zOrder = androidZOrderMap.get(mSubscriber.getSession().getSessionId());
                }
            }
            mSubscriber.setStyle(BaseVideoRenderer.STYLE_VIDEO_SCALE,
                BaseVideoRenderer.STYLE_VIDEO_FILL);
            if (pubOrSub.equals("subscriber") && mSubscriber.getView() instanceof GLSurfaceView) {
                if (zOrder.equals("mediaOverlay")) {
                    ((GLSurfaceView) mSubscriber.getView()).setZOrderMediaOverlay(true);
                } else {
                    ((GLSurfaceView) mSubscriber.getView()).setZOrderOnTop(true);
                }
            }
            ConcurrentHashMap<String, FrameLayout> mSubscriberViewContainers = sharedState.getSubscriberViewContainers();
            mSubscriberViewContainers.put(streamId, mSubscriberViewContainer);
            addView(mSubscriberViewContainer, 0);
            mSubscriberViewContainer.addView(mSubscriber.getView());
            requestLayout();
        }
    }

}
