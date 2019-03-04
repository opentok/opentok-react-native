package com.opentokreactnative;

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
        Subscriber mSubscriber = mSubscribers.get(streamId);
        FrameLayout mSubscriberViewContainer = new FrameLayout(getContext());
        if (mSubscriber != null) {
            mSubscriber.setStyle(BaseVideoRenderer.STYLE_VIDEO_SCALE,
                BaseVideoRenderer.STYLE_VIDEO_FILL);
            ConcurrentHashMap<String, FrameLayout> mSubscriberViewContainers = sharedState.getSubscriberViewContainers();
            mSubscriberViewContainers.put(streamId, mSubscriberViewContainer);
            addView(mSubscriberViewContainer, 0);
            mSubscriberViewContainer.addView(mSubscriber.getView());
            requestLayout();
        }
    }

}
