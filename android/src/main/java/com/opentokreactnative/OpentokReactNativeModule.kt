package com.opentokreactnative

import android.content.Context
import android.content.SharedPreferences
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Promise;
import com.opentok.android.Connection;
import com.opentok.android.OpentokError
import com.opentok.android.Session
import com.opentok.android.Session.SessionListener
import com.opentok.android.Session.SignalListener
import com.opentok.android.Stream

class OpentokReactNativeModule(reactContext: ReactApplicationContext) : NativeOpentokReactNativeSpec(reactContext), SessionListener, SignalListener {
  private lateinit var session: Session
  private var context = reactContext
  private var sharedState = OTRN.getSharedState();

  override fun getName() = NAME


  override fun initSession(apiKey: String, sessionId: String, options: ReadableMap?) {

    session = Session.Builder(context, apiKey, sessionId)
                .build()

    sharedState.getSessions().put(sessionId, session);

    session.setSessionListener(this)
    session.setSignalListener(this)
  }

  override fun connect(sessionId: String, token: String, promise: Promise) {
    session.connect(token)
    promise.resolve(null)
  }

  override fun disconnect(sessionId: String, promise: Promise) {
    session.disconnect()
    promise.resolve(null)
  }

  override fun sendSignal(sessionId: String, type: String, data: String) {
    session.sendSignal(type, data)
  }

  override fun getSubscriberRtcStatsReport() {
    val subscribers = sharedState.getSubscribers()
    val subscriberList = ArrayList(subscribers.values)
        for (subscriber in subscriberList) {
            subscriber.getRtcStatsReport();
        }
    }

  override fun onConnected(session: Session) {
      val payload =
        Arguments.createMap().apply {
          putString("sessionId", session.getSessionId())
          putString("connectionId", session.getConnection().getConnectionId())
        }
      emitOnSessionConnected(payload)
  }

  override fun onDisconnected(session: Session) {
      val payload =
        Arguments.createMap().apply {
          putString("sessionId", session.getSessionId())
          putString("connectionId", session.getConnection().getConnectionId())
        }
      emitOnSessionDisconnected(payload)
  }

  override fun onStreamReceived(session: Session, stream: Stream) {
      sharedState.getSubscriberStreams().put(stream.streamId, stream);
      val payload =
        Arguments.createMap().apply {
          putString("streamId", stream.streamId)
        }
      emitOnStreamCreated(payload)
  }

  override fun onStreamDropped(session: Session, stream: Stream) {
      val payload =
        Arguments.createMap().apply {
          putString("streamId", stream.streamId)
        }
      emitOnStreamDestroyed(payload)
  }

  override fun onError(session: Session, opentokError: OpentokError) {
      val payload =
        Arguments.createMap().apply {
          putString("sessionId", session.sessionId)
          putString("code", opentokError.errorCode.toString())
          putString("message", opentokError.message)
        }
      emitOnSessionError(payload)
  }

  override fun onSignalReceived(session: Session, type: String, data: String, connection: Connection) {
      val payload =
        Arguments.createMap().apply {
          putString("sessionId", session.sessionId)
          putString("connectionId", connection.connectionId)
          putString("type", type)
          putString("data", data)
        }
      emitOnSignalReceived(payload)
  }

  companion object {
    const val NAME = "OpentokReactNative"
  }
}
