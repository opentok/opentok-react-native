package com.opentokreactnative

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewManagerDelegate;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.viewmanagers.OTRNSubscriberManagerInterface;
import com.facebook.react.viewmanagers.OTRNSubscriberManagerDelegate;

@ReactModule(name = OTRNSubscriberManager.REACT_CLASS)
@Suppress("UNUSED_PARAMETER")
class OTRNSubscriberManager(context: ReactApplicationContext) :
    SimpleViewManager<OTRNSubscriber>(),
    OTRNSubscriberManagerInterface<OTRNSubscriber> {
    private val delegate: OTRNSubscriberManagerDelegate<OTRNSubscriber, OTRNSubscriberManager> =
        OTRNSubscriberManagerDelegate(this)

    override fun getDelegate(): ViewManagerDelegate<OTRNSubscriber> = delegate

    override fun getName(): String = REACT_CLASS

    override fun createViewInstance(context: ThemedReactContext): OTRNSubscriber =
        OTRNSubscriber(context)

    @ReactProp(name = "streamId")
    override public fun setStreamId(view: OTRNSubscriber, streamId: String?) {
        view.setStreamId(streamId)
    }

    @ReactProp(name = "sessionId")
    override public fun setSessionId(view: OTRNSubscriber, sessionId: String?) {
        view.setSessionId(sessionId)
    }

    @ReactProp(name = "scaleBehavior")
    override public fun setScaleBehavior(view: OTRNSubscriber, value: String?) {
        view.setScaleBehavior(value)
    }

    override fun setSubscribeToAudio(
        view: OTRNSubscriber?,
        value: Boolean
    ) {
        view?.setSubscribeToAudio(value)
    }

    override fun setSubscribeToVideo(
        view: OTRNSubscriber?,
        value: Boolean
    ) {
        view?.setSubscribeToVideo(value)
    }

    override fun setSubscribeToCaptions(
        view: OTRNSubscriber?,
        value: Boolean
    ) {
        view?.setSubscribeToCaptions(value)
    }

    override fun setAudioVolume(
        view: OTRNSubscriber?,
        value: Float
    ) {
        view?.setAudioVolume(value)
    }

    override fun setPreferredFrameRate(
        view: OTRNSubscriber?,
        value: Int
    ) {
        view?.setPreferredFrameRate(value)
    }

    override fun setPreferredResolution(
        view: OTRNSubscriber?,
        value: String?
    ) {
        view?.setPreferredResolution(value)
    }

    override fun updateProperties(
        viewToUpdate: OTRNSubscriber,
        props: ReactStylesDiffMap?
    ) {
        super.updateProperties(viewToUpdate, props)
        viewToUpdate.updateProperties(props)
    }

    companion object {
        const val REACT_CLASS = "OTRNSubscriber"
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