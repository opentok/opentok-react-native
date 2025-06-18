package com.opentokreactnative

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewManagerDelegate;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.viewmanagers.OTPublisherViewNativeManagerInterface;
import com.facebook.react.viewmanagers.OTPublisherViewNativeManagerDelegate;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.ReactStylesDiffMap


@ReactModule(name = OTPublisherViewNativeManager.REACT_CLASS)
class OTPublisherViewNativeManager(context: ReactApplicationContext) :
    SimpleViewManager<OTPublisherViewNative>(),
    OTPublisherViewNativeManagerInterface<OTPublisherViewNative> {
    private val delegate: OTPublisherViewNativeManagerDelegate<OTPublisherViewNative, OTPublisherViewNativeManager> =
        OTPublisherViewNativeManagerDelegate(this)

    override fun getDelegate(): ViewManagerDelegate<OTPublisherViewNative> = delegate

    override fun getName(): String = REACT_CLASS

    override fun createViewInstance(context: ThemedReactContext): OTPublisherViewNative {
        Log.d("OTPublisherViewNativeManager", "createViewInstance: $nativeProps")
        return OTPublisherViewNative(context)
    }

    override fun getNativeProps(): Map<String?, String?>? {
        return super.getNativeProps()
    }

    override fun updateProperties(
        viewToUpdate: OTPublisherViewNative,
        props: ReactStylesDiffMap?
    ) {
        super.updateProperties(viewToUpdate, props)
        Log.d("OTPublisherViewNativeManager", "updateProperties: $props")
        viewToUpdate.updateProperties(props)
    }

    override fun setSessionId(
        view: OTPublisherViewNative?,
        value: String?
    ) {
        view?.setSessionId(value)
    }

    //@ReactProp(name = "sessionId")
    //override public fun setSessionId(view: OTPublisherViewNative, sessionId: String?) {
       // view.setSessionId(sessionId)
    //}

    //@ReactProp(name = "publisherId")
    override public fun setPublisherId(view: OTPublisherViewNative, publisherId: String?) {
        view.setPublisherId(publisherId)
    }

    @ReactProp(name = "publishAudio")
    override public fun setPublishAudio(view: OTPublisherViewNative, value: Boolean) {
        view.setPublishAudio(value)
    }

    @ReactProp(name = "publishVideo")
    override public fun setPublishVideo(view: OTPublisherViewNative, value: Boolean) {
        Log.d("OTPublisherViewNativeManager", "setPublishVideo: $value")
        view.setPublishVideo(value)
    }

    @ReactProp(name = "publishCaptions")
    override public fun setPublishCaptions(view: OTPublisherViewNative, value: Boolean) {
        view.setPublishCaptions(value)
    }

    @ReactProp(name = "audioFallbackEnabled")
    override public fun setAudioFallbackEnabled(view: OTPublisherViewNative, value: Boolean) {
        view.setAudioFallbackEnabled(value)
    }

    @ReactProp(name = "audioBitrate")
    override public fun setAudioBitrate(view: OTPublisherViewNative, value: Int) {
        view.setAudioBitrate(value)
    }

    @ReactProp(name = "publisherAudioFallback")
    override public fun setPublisherAudioFallback(view: OTPublisherViewNative, value: Boolean) {
        view.setPublisherAudioFallback(value)
    }

    @ReactProp(name = "subscriberAudioFallback")
    override public fun setSubscriberAudioFallback(view: OTPublisherViewNative, value: Boolean) {
        view.setSubscriberAudioFallback(value)
    }

    @ReactProp(name = "audioTrack")
    override public fun setAudioTrack(view: OTPublisherViewNative, value: Boolean) {
        view.setAudioTrack(value)
    }

    @ReactProp(name = "videoTrack")
    override public fun setVideoTrack(view: OTPublisherViewNative, value: Boolean) {
        view.setVideoTrack(value)
    }

    @ReactProp(name = "videoSource")
    override public fun setVideoSource(view: OTPublisherViewNative, value: String?) {
        view.setVideoSource(value)
    }

    @ReactProp(name = "videoContentHint")
    override public fun setVideoContentHint(view: OTPublisherViewNative, value: String?) {
        view.setVideoContentHint(value)
    }

    @ReactProp(name = "cameraPosition")
    override public fun setCameraPosition(view: OTPublisherViewNative, value: String?) {
        view.setCameraPosition(value)
    }

    @ReactProp(name = "cameraTorch")
    override public fun setCameraTorch(view: OTPublisherViewNative, value: Boolean) {
        view.setCameraTorch(value)
    }

    @ReactProp(name = "cameraZoomFactor")
    override public fun setCameraZoomFactor(view: OTPublisherViewNative, value: Float) {
        view.setCameraZoomFactor(value)
    }

    @ReactProp(name = "enableDtx")
    override public fun setEnableDtx(view: OTPublisherViewNative, value: Boolean) {
        view.setEnableDtx(value)
    }

    @ReactProp(name = "frameRate")
    override public fun setFrameRate(view: OTPublisherViewNative, value: Int) {
        view.setFrameRate(value)
    }

    @ReactProp(name = "name")
    override public fun setName(view: OTPublisherViewNative, value: String?) {
        view.setName(value)
    }

    @ReactProp(name = "resolution")
    override public fun setResolution(view: OTPublisherViewNative, value: String?) {
        view.setResolution(value)
    }

    @ReactProp(name = "scalableScreenshare")
    override public fun setScalableScreenshare(view: OTPublisherViewNative, value: Boolean) {
        view.setScalableScreenshare(value)
    }

    companion object {
        const val REACT_CLASS = "OTPublisherViewNative"
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