package com.opentokreactnative;

import android.view.Gravity;
import android.widget.FrameLayout;
import android.opengl.GLSurfaceView;

import com.facebook.react.uimanager.ThemedReactContext;
import com.opentok.android.BaseVideoRenderer;
import com.opentok.android.Publisher;

import java.util.concurrent.ConcurrentHashMap;

/**
 * Created by manik on 1/10/18.
 */

public class OTPublisherLayout extends FrameLayout{

    public OTRN sharedState;

    public OTPublisherLayout(ThemedReactContext reactContext) {

        super(reactContext);
        sharedState = OTRN.getSharedState();
    }

    public void createPublisherView(String publisherId) {

        ConcurrentHashMap<String, Publisher> mPublishers = sharedState.getPublishers();
        Publisher mPublisher = mPublishers.get(publisherId);        
        mPublisher.setStyle(BaseVideoRenderer.STYLE_VIDEO_SCALE,
                BaseVideoRenderer.STYLE_VIDEO_FILL);
        FrameLayout mPublisherViewContainer = new FrameLayout(getContext());
        if (mPublisher.getView() instanceof GLSurfaceView) {
            ((GLSurfaceView) mPublisher.getView()).setZOrderOnTop(true);
        }
        ConcurrentHashMap<String, FrameLayout> mPublisherViewContainers = sharedState.getPublisherViewContainers();
        mPublisherViewContainers.put(publisherId, mPublisherViewContainer);
        addView(mPublisherViewContainers.get(publisherId), 0);
        mPublisherViewContainers.get(publisherId).addView(mPublisher.getView());
        requestLayout();

    }

}
