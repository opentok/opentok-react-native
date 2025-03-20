package com.opentokreactnative;

import android.content.Context;
import android.content.SharedPreferences;
import java.util.ArrayList;
import java.util.concurrent.ConcurrentHashMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;
import com.opentok.android.Connection;
import com.opentok.android.OpentokError;
import com.opentok.android.Publisher;
import com.opentok.android.Session;
import com.opentok.android.Session.SessionListener;
import com.opentok.android.Session.SignalListener;
import com.opentok.android.Stream;
import com.opentok.android.Subscriber;

public class OpentokReactNativeModule extends NativeOpentokReactNativeSpec implements SessionListener, SignalListener {

  public static final String NAME = "OpentokReactNative";

  private Session session;
  private ReactApplicationContext context = null;
  private OTRN sharedState = OTRN.getSharedState();

  @Override
  public String getName() {
    return NAME;
  }

  public OpentokReactNativeModule(ReactApplicationContext reactContext) {
    super(reactContext);
    context = reactContext;
  }

  @Override
  public void initSession(String apiKey, String sessionId, ReadableMap options) {

    session = new Session.Builder(context, apiKey, sessionId)
                .build();

    sharedState.getSessions().put(sessionId, session);

    session.setSessionListener(this);
    session.setSignalListener(this);
  }

  @Override
  public void connect(String sessionId, String token, Promise promise) {
    session.connect(token);
    promise.resolve(null);
  }

  @Override
  public void disconnect(String sessionId, Promise promise) {
    session.disconnect();
    promise.resolve(null);
  }

  @Override
  public void sendSignal(String sessionId, String type, String data) {
    session.sendSignal(type, data);
  }

  @Override
  public void getSubscriberRtcStatsReport() {
    ConcurrentHashMap<String, Subscriber> subscribers = sharedState.getSubscribers();
    ArrayList<Subscriber> subscriberList = new ArrayList<>(subscribers.values());
    for (Subscriber subscriber : subscriberList) {
          subscriber.getRtcStatsReport();
      }
  }

  @Override
  public void publish(String publisherId) {
    ConcurrentHashMap<String, Publisher> publishers = sharedState.getPublishers();
    Publisher publisher = publishers.get(publisherId);
    if (publisher != null) {
      session.publish(publisher);
    }
  }

  @Override
  public void disableForceMute(String sessionId, Promise promise) {
    // TODO
  }

  @Override
  public void forceMuteAll(String sesssionId, ReadableArray excludedStreamIds, Promise promise) {
    // TODO
  }

  @Override
  public void forceMuteStream(String sesssionId, String streamId, Promise promise) {
    // TODO
  }

  @Override
  public void getPublisherRtcStatsReport(String publisherId) {
    ConcurrentHashMap<String, Publisher> publishers = sharedState.getPublishers();
    Publisher publisher = publishers.get(publisherId);
    if (publisher != null) {
      publisher.getRtcStatsReport();
    }
  }

  @Override
  public void setAudioTransformers(String publisherId, ReadableArray audioTransformers) {
    // TODO
  }

  @Override
  public void setVideoTransformers(String publisherId, ReadableArray videoTransformers) {
    // TODO
  }

  @Override
  public void reportIssue(String sessionId, Promise promise) {
    // TODO
  }

  @Override
  public void setEncryptionSecret(String sessionId, String secret, Promise promise) {
    // TODO
  }

  @Override
  public void onConnected(Session session) {
    WritableMap payload = Arguments.createMap();
    payload.putString("sessionId", session.getSessionId());
    payload.putString("connectionId", session.getConnection().getConnectionId());
    emitOnSessionConnected(payload);
  }

  @Override
  public void onDisconnected(Session session) {
    WritableMap payload = Arguments.createMap();
    payload.putString("sessionId", session.getSessionId());
    payload.putString("connectionId", session.getConnection().getConnectionId());
    emitOnSessionDisconnected(payload);
  }

  @Override
  public void onStreamReceived(Session session, Stream stream) {
    sharedState.getSubscriberStreams().put(stream.getStreamId(), stream);
    WritableMap payload = Arguments.createMap();
    payload.putString("streamId", stream.getStreamId());
    emitOnStreamCreated(payload);
  }

  @Override
  public void onStreamDropped(Session session, Stream stream) {
    WritableMap payload = Arguments.createMap();
    payload.putString("streamId", stream.getStreamId());
    emitOnStreamDestroyed(payload);
  }

  @Override
  public void onError(Session session, OpentokError opentokError ) {
    WritableMap payload = Arguments.createMap();
    payload.putString("sessionId", session.getSessionId());
    payload.putString("code", opentokError.getErrorCode().toString());
    payload.putString("message", opentokError.getMessage());

    emitOnSessionError(payload);
  }

  @Override
  public void onSignalReceived(Session session, String type, String data, Connection connection) {
    WritableMap payload = Arguments.createMap();
    payload.putString("sessionId", session.getSessionId());
    payload.putString("connectionId", connection.getConnectionId());
    payload.putString("type", type);
    payload.putString("data", data);
    emitOnSignalReceived(payload);
  }
}
