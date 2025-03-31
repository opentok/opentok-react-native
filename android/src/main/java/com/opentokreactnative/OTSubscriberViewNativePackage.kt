package com.opentokreactnative

import com.facebook.react.TurboReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager

class OTSubscriberViewNativePackage : TurboReactPackage() {
    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return listOf(OTSubscriberViewNativeManager(reactContext))
    }

    override fun getModule(
        s: String,
        reactApplicationContext: ReactApplicationContext
    ): NativeModule? {
        when (s) {
            OTSubscriberViewNativeManager.REACT_CLASS -> OTSubscriberViewNativeManager(
                reactApplicationContext
            )
        }
        return null
    }

    override fun getReactModuleInfoProvider(): ReactModuleInfoProvider = ReactModuleInfoProvider {
        mapOf(
            OTSubscriberViewNativeManager.REACT_CLASS to ReactModuleInfo(
                OTSubscriberViewNativeManager.REACT_CLASS, // _name =
                OTSubscriberViewNativeManager.REACT_CLASS, // _className =
                false, // _canOverrideExistingModule =
                false, // _needsEagerInit =
                true,  // hasConstants
                false, // isCxxModule =
                true, // isTurboModule =
            )
        )
    }
}