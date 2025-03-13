package com.opentokreactnative

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewManagerDelegate;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.viewmanagers.OTPublisherViewNativeManagerInterface;
import com.facebook.react.viewmanagers.OTPublisherViewNativeManagerDelegate;

@ReactModule(name = OTPublisherViewNativeManager.REACT_CLASS)
class OTPublisherViewNativeManager(context: ReactApplicationContext) : SimpleViewManager<OTPublisherViewNative>(), OTPublisherViewNativeManagerInterface<OTPublisherViewNative> {
  private val delegate: OTPublisherViewNativeManagerDelegate<OTPublisherViewNative, OTPublisherViewNativeManager> =
    OTPublisherViewNativeManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<OTPublisherViewNative> = delegate

  override fun getName(): String = REACT_CLASS

  override fun createViewInstance(context: ThemedReactContext): OTPublisherViewNative = OTPublisherViewNative(context)

  @ReactProp(name = "sessionId")
  override public fun setSessionId(view: OTPublisherViewNative, sessionId: String?) {
    view.setSessionId(sessionId)
  }

  @ReactProp(name = "publisherId")
  override public fun setPublisherId(view: OTPublisherViewNative, publisherId: String?) {
    view.setPublisherId(publisherId)
  }

  @ReactProp(name = "publishAudio")
  override public fun setPublishAudio(view: OTPublisherViewNative, value: Boolean) {
    view.setPublishAudio(value)
  }

  @ReactProp(name = "publishVideo")
  override public fun setPublishVideo(view: OTPublisherViewNative, value: Boolean) {
    view.setPublishVideo(value)
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
                      )))
}