package com.opentokreactnative

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Promise;
import com.opentok.android.Session

@ReactModule(name = OpentokReactNativeModule.NAME)
class OpentokReactNativeModule(reactContext: ReactApplicationContext) :
  NativeOpentokReactNativeSpec(reactContext) {
  private lateinit var session: Session
  private var context = reactContext

  override fun getName(): String {
    return NAME
  }

  override fun initSession(apiKey: String, sessionId: String, options: ReadableMap?) {

    session = Session.Builder(context, apiKey, sessionId)
                .build()

    // sharedState.getSessions().put(sessionId, session);

    // session.setSessionListener(this)
    // session.setSignalListener(this)
  }

  override fun connect(sessionId: String, token: String, promise: Promise) {
    session.connect(token)
    promise.resolve(null)
  }

  override fun sendSignal(sessionId: String, type: String, data: String) {
    session.sendSignal(type, data)
  }

  companion object {
    const val NAME = "OpentokReactNative"
  }
}
