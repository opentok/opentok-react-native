package com.opentokreactnative

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewManagerDelegate;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.viewmanagers.OTRNPublisherManagerInterface;
import com.facebook.react.viewmanagers.OTRNPublisherManagerDelegate;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.ReactStylesDiffMap


@ReactModule(name = OTRNPublisherManager.REACT_CLASS)
@Suppress("UNUSED_PARAMETER")
class OTRNPublisherManager(context: ReactApplicationContext) :
    SimpleViewManager<OTRNPublisher>(),
    OTRNPublisherManagerInterface<OTRNPublisher> {
    private val delegate: OTRNPublisherManagerDelegate<OTRNPublisher, OTRNPublisherManager> =
        OTRNPublisherManagerDelegate(this)

    override fun getDelegate(): ViewManagerDelegate<OTRNPublisher> = delegate

    override fun getName(): String = REACT_CLASS

    override fun createViewInstance(context: ThemedReactContext): OTRNPublisher {
        Log.d("OTRNPublisherManager", "createViewInstance: $nativeProps")
        return OTRNPublisher(context)
    }

    override fun getNativeProps(): Map<String?, String?>? {
        return super.getNativeProps()
    }

    override fun updateProperties(
        viewToUpdate: OTRNPublisher,
        props: ReactStylesDiffMap?
    ) {
        super.updateProperties(viewToUpdate, props)
        Log.d("OTRNPublisherManager", "updateProperties: $props")
        viewToUpdate.updateProperties(props)
    }

    override fun setSessionId(
        view: OTRNPublisher?,
        value: String?
    ) {
        view?.setSessionId(value)
    }

    //@ReactProp(name = "sessionId")
    //override public fun setSessionId(view: OTRNPublisher, sessionId: String?) {
       // view.setSessionId(sessionId)
    //}

    //@ReactProp(name = "publisherId")
    override public fun setPublisherId(view: OTRNPublisher, publisherId: String?) {
        view.setPublisherId(publisherId)
    }

    @ReactProp(name = "publishAudio")
    override public fun setPublishAudio(view: OTRNPublisher, value: Boolean) {
        view.setPublishAudio(value)
    }

    @ReactProp(name = "publishVideo")
    override public fun setPublishVideo(view: OTRNPublisher, value: Boolean) {
        Log.d("OTRNPublisherManager", "setPublishVideo: $value")
        view.setPublishVideo(value)
    }

    @ReactProp(name = "publishCaptions")
    override public fun setPublishCaptions(view: OTRNPublisher, value: Boolean) {
        view.setPublishCaptions(value)
    }

    @ReactProp(name = "audioFallbackEnabled")
    override public fun setAudioFallbackEnabled(view: OTRNPublisher, value: Boolean) {
        view.setAudioFallbackEnabled(value)
    }

    @ReactProp(name = "audioBitrate")
    override public fun setAudioBitrate(view: OTRNPublisher, value: Int) {
        view.setAudioBitrate(value)
    }

    @ReactProp(name = "publisherAudioFallback")
    override public fun setPublisherAudioFallback(view: OTRNPublisher, value: Boolean) {
        view.setPublisherAudioFallback(value)
    }

    @ReactProp(name = "subscriberAudioFallback")
    override public fun setSubscriberAudioFallback(view: OTRNPublisher, value: Boolean) {
        view.setSubscriberAudioFallback(value)
    }

    @ReactProp(name = "audioTrack")
    override public fun setAudioTrack(view: OTRNPublisher, value: Boolean) {
        view.setAudioTrack(value)
    }

    @ReactProp(name = "videoTrack")
    override public fun setVideoTrack(view: OTRNPublisher, value: Boolean) {
        view.setVideoTrack(value)
    }

    @ReactProp(name = "videoSource")
    override public fun setVideoSource(view: OTRNPublisher, value: String?) {
        view.setVideoSource(value)
    }

    @ReactProp(name = "videoContentHint")
    override public fun setVideoContentHint(view: OTRNPublisher, value: String?) {
        view.setVideoContentHint(value)
    }

    @ReactProp(name = "maxVideoBitrate")
    override public fun setMaxVideoBitrate(view: OTRNPublisher, value: Int) {
        view.setMaxVideoBitrate(value)
    }

    @ReactProp(name = "videoBitratePreset")
    override public fun setVideoBitratePreset(view: OTRNPublisher, value: String?) {
        view.setVideoBitratePreset(value)
    }

    @ReactProp(name = "cameraPosition")
    override public fun setCameraPosition(view: OTRNPublisher, value: String?) {
        view.setCameraPosition(value)
    }

    @ReactProp(name = "cameraTorch")
    override public fun setCameraTorch(view: OTRNPublisher, value: Boolean) {
        view.setCameraTorch(value)
    }

    @ReactProp(name = "cameraZoomFactor")
    override public fun setCameraZoomFactor(view: OTRNPublisher, value: Float) {
        view.setCameraZoomFactor(value)
    }

    @ReactProp(name = "enableDtx")
    override public fun setEnableDtx(view: OTRNPublisher, value: Boolean) {
        view.setEnableDtx(value)
    }

    @ReactProp(name = "frameRate")
    override public fun setFrameRate(view: OTRNPublisher, value: Int) {
        view.setFrameRate(value)
    }

    @ReactProp(name = "name")
    override public fun setName(view: OTRNPublisher, value: String?) {
        view.setName(value)
    }

    @ReactProp(name = "resolution")
    override public fun setResolution(view: OTRNPublisher, value: String?) {
        view.setResolution(value)
    }

    @ReactProp(name = "scalableScreenshare")
    override public fun setScalableScreenshare(view: OTRNPublisher, value: Boolean) {
        view.setScalableScreenshare(value)
    }

    @ReactProp(name = "allowAudioCaptureWhileMuted")
    override public fun setAllowAudioCaptureWhileMuted(view: OTRNPublisher, value: Boolean) {
        view.setAllowAudioCaptureWhileMuted(value)
    }

    @ReactProp(name = "scaleBehavior")
    override public fun setScaleBehavior(view: OTRNPublisher, value: String?) {
        view.setScaleBehavior(value)
    }

    companion object {
        const val REACT_CLASS = "OTRNPublisher"
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