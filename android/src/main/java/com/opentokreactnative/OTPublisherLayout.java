package com.opentokreactnative;

import android.view.Gravity;
import android.widget.FrameLayout;

import com.facebook.react.uimanager.ThemedReactContext;
import com.opentok.android.BaseVideoRenderer;
import com.opentok.android.Publisher;

/**
 * Created by manik on 1/10/18.
 */

public class OTPublisherLayout extends FrameLayout{

    public OTRN sharedState;
    private FrameLayout mPublisherViewContainer;

    public OTPublisherLayout(ThemedReactContext reactContext) {

        super(reactContext);
        sharedState = OTRN.getSharedState();
        createPublisherView();
    }

    private void createPublisherView() {

        Publisher mPublisher = sharedState.getPublisher();
        mPublisher.setStyle(BaseVideoRenderer.STYLE_VIDEO_SCALE,
                BaseVideoRenderer.STYLE_VIDEO_FILL);
        mPublisherViewContainer = new FrameLayout(getContext());
        addView(mPublisherViewContainer, 0);
        mPublisherViewContainer.addView(mPublisher.getView());
        requestLayout();
        sharedState.setPublisher(mPublisher);
        sharedState.setPublisherViewContainer(mPublisherViewContainer);
    }

}

