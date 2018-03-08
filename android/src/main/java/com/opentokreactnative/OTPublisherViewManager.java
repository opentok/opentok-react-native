package com.opentokreactnative;

/**
 * Created by manik on 1/10/18.
 */

import android.util.Log;

import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.ThemedReactContext;


public class OTPublisherViewManager extends ViewGroupManager<OTPublisherLayout> {

    @Override
    public String getName() {

        return this.getClass().getSimpleName();
    }

    @Override
    protected OTPublisherLayout createViewInstance(ThemedReactContext reactContext) {

        return new OTPublisherLayout(reactContext);
    }

}
