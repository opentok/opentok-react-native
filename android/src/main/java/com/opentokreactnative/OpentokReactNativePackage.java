package com.opentokreactnative;

import com.facebook.react.BaseReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.module.model.ReactModuleInfo;
import com.facebook.react.module.model.ReactModuleInfoProvider;

import java.util.HashMap;
import java.util.Map;

public class OpentokReactNativePackage extends BaseReactPackage {
    public NativeModule getModule(String name, ReactApplicationContext reactContext) {
        if (name.equals(OpentokReactNativeModule.NAME)) {
            return new OpentokReactNativeModule(reactContext);
        } else {
            return null;
        }
    }

    @Override
    public ReactModuleInfoProvider getReactModuleInfoProvider() {
        return new ReactModuleInfoProvider() {
            @Override
            public Map<String, ReactModuleInfo> getReactModuleInfos() {
                Map<String, ReactModuleInfo> map = new HashMap<>();
                map.put(OpentokReactNativeModule.NAME, new ReactModuleInfo(
                        OpentokReactNativeModule.NAME, // name
                        OpentokReactNativeModule.NAME, // className
                        false,  // canOverrideExistingModule
                        false,  // needsEagerInit
                        false,  // isCxxModule
                        true // isTurboModule
                ));
                return map;
            }
        };
    }
}

