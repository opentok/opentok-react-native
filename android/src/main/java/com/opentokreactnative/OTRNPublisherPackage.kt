package com.opentokreactnative

import com.facebook.react.TurboReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager

class OTRNPublisherPackage : TurboReactPackage() {
    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return listOf(OTRNPublisherManager(reactContext))
    }

    override fun getModule(
        s: String,
        reactApplicationContext: ReactApplicationContext
    ): NativeModule? {
        when (s) {
            OTRNPublisherManager.REACT_CLASS -> OTRNPublisherManager(
                reactApplicationContext
            )
        }
        return null
    }

    override fun getReactModuleInfoProvider(): ReactModuleInfoProvider = ReactModuleInfoProvider {
        mapOf(
            OTRNPublisherManager.REACT_CLASS to ReactModuleInfo(
                OTRNPublisherManager.REACT_CLASS, // _name =
                OTRNPublisherManager.REACT_CLASS, // _className =
                false, // _canOverrideExistingModule =
                false, // _needsEagerInit =
                true,  // hasConstants
                false, // isCxxModule =
                true, // isTurboModule =
            )
        )
    }
}