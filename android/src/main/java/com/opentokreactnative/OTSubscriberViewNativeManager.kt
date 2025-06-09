package com.opentokreactnative

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewManagerDelegate;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.viewmanagers.OTSubscriberViewNativeManagerInterface;
import com.facebook.react.viewmanagers.OTSubscriberViewNativeManagerDelegate;

@ReactModule(name = OTSubscriberViewNativeManager.REACT_CLASS)
class OTSubscriberViewNativeManager(context: ReactApplicationContext) :
    SimpleViewManager<OTSubscriberViewNative>(),
    OTSubscriberViewNativeManagerInterface<OTSubscriberViewNative> {
    private val delegate: OTSubscriberViewNativeManagerDelegate<OTSubscriberViewNative, OTSubscriberViewNativeManager> =
        OTSubscriberViewNativeManagerDelegate(this)

    override fun getDelegate(): ViewManagerDelegate<OTSubscriberViewNative> = delegate

    override fun getName(): String = REACT_CLASS

    override fun createViewInstance(context: ThemedReactContext): OTSubscriberViewNative =
        OTSubscriberViewNative(context)

    @ReactProp(name = "streamId")
    override public fun setStreamId(view: OTSubscriberViewNative, streamId: String?) {
        view.setStreamId(streamId)
    }

    @ReactProp(name = "sessionId")
    override public fun setSessionId(view: OTSubscriberViewNative, sessionId: String?) {
        view.setSessionId(sessionId)
    }

    override fun setSubscribeToAudio(
        view: OTSubscriberViewNative?,
        value: Boolean
    ) {
        view?.setSubscribeToAudio(value)
    }

    override fun setSubscribeToVideo(
        view: OTSubscriberViewNative?,
        value: Boolean
    ) {
        view?.setSubscribeToVideo(value)
    }

    override fun setSubscribeToCaptions(
        view: OTSubscriberViewNative?,
        value: Boolean
    ) {
        view?.setSubscribeToCaptions(value)
    }

    override fun setAudioVolume(
        view: OTSubscriberViewNative?,
        value: Float
    ) {
        view?.setAudioVolume(value)
    }

    override fun setPreferredFrameRate(
        view: OTSubscriberViewNative?,
        value: Int
    ) {
        view?.setPreferredFrameRate(value)
    }

    override fun setPreferredResolution(
        view: OTSubscriberViewNative?,
        value: String?
    ) {
        view?.setPreferredResolution(value)
    }

    override fun updateProperties(
        viewToUpdate: OTSubscriberViewNative,
        props: ReactStylesDiffMap?
    ) {
        super.updateProperties(viewToUpdate, props)
        viewToUpdate.updateProperties(props)
    }

    companion object {
        const val REACT_CLASS = "OTSubscriberViewNative"
    }

    override fun getExportedCustomBubblingEventTypeConstants(): Map<String, Any> =
        mapOf(
            "onSubscriberConnected" to
                    mapOf(
                        "phasedRegistrationNames" to
                                mapOf(
                                    "bubbled" to "onSubscriberConnected",
                                    "captured" to "onSubscriberConnectedCapture"
                                )
                    )
        )
}