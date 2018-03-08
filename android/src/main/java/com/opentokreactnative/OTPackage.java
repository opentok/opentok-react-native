package com.opentokreactnative;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
/**
 * Created by manik on 1/9/18.
 */

public class OTPackage implements ReactPackage {

    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {

        return Arrays.<ViewManager>asList(
                new OTPublisherViewManager(),
                new OTSubscriberViewManager()
        );
    }

    @Override
    public List<NativeModule> createNativeModules(

            ReactApplicationContext reactContext) {
        List<NativeModule> modules = new ArrayList<>();

        modules.add(new OTSessionManager(reactContext));

        return modules;
    }
}
