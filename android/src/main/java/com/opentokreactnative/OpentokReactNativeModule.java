package com.opentokreactnative;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.concurrent.ConcurrentHashMap;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;
import com.opentok.android.Connection;
import com.opentok.android.MuteForcedInfo;
import com.opentok.android.OpentokError;
import com.opentok.android.Publisher;
import com.opentok.android.PublisherKit;
import com.opentok.android.Session;
import com.opentok.android.Session.SessionListener;
import com.opentok.android.Session.SignalListener;
import com.opentok.android.Stream;
import com.opentok.android.Subscriber;
import com.opentokreactnative.utils.EventUtils;
import com.opentokreactnative.utils.Utils;


public class OpentokReactNativeModule extends NativeOpentokReactNativeSpec implements
        SessionListener,
        SignalListener,
        Session.ConnectionListener,
        Session.ReconnectionListener,
        Session.ArchiveListener,
        Session.MuteListener,
        Session.StreamPropertiesListener,
        Session.StreamCaptionsPropertiesListener,
        // Revisit this
        Application.ActivityLifecycleCallbacks {
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

        session.setArchiveListener(this);
        session.setConnectionListener(this);
        session.setMuteListener(this);
        session.setMuteListener(this);
        session.setSessionListener(this);
        session.setSignalListener(this);
        session.setStreamCaptionsPropertiesListener(this);
        session.setStreamPropertiesListener(this);
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

    // @Override Move this to publisher code
    public void setAudioTransformers(String publisherId, ReadableArray audioTransformers) {
        ConcurrentHashMap<String, Publisher> publishers = sharedState.getPublishers();
        Publisher publisher = publishers.get(publisherId);
        if (publisher != null) {
            ArrayList<PublisherKit.AudioTransformer> nativeAudioTransformers = Utils.sanitizeAudioTransformerList(publisher, audioTransformers);
            publisher.setAudioTransformers(nativeAudioTransformers);
        }
    }

    //@Override Move this to publisher code
    public void setVideoTransformers(String publisherId, ReadableArray videoTransformers) {
        ConcurrentHashMap<String, Publisher> publishers = sharedState.getPublishers();
        Publisher publisher = publishers.get(publisherId);
        if (publisher != null) {
            ArrayList<PublisherKit.VideoTransformer> nativeVideoTransformers = Utils.sanitizeVideoTransformerList(publisher, videoTransformers);
            publisher.setVideoTransformers(nativeVideoTransformers);
        }
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
    public void onError(Session session, OpentokError opentokError) {
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

    @Override
    public void onArchiveStarted(Session session, String id, String name) {
        WritableMap payload = Arguments.createMap();
        payload.putString("sessionId", session.getSessionId());
        payload.putString("archiveId", id);
        payload.putString("name", name);
        emitOnArchiveStarted(payload);
    }

    @Override
    public void onArchiveStopped(Session session, String id) {
        WritableMap archiveInfo = Arguments.createMap();
        archiveInfo.putString("archiveId", id);
        archiveInfo.putString("name", "");
        archiveInfo.putString("sessionId", session.getSessionId());
        emitOnArchiveStopped(archiveInfo);
    }

    @Override
    public void onConnectionCreated(Session session, Connection connection) {
        //sharedState.getConnections().put(connection.getConnectionId(), connection);
        WritableMap eventData = Arguments.createMap();
        eventData.putString("sessionId", session.getSessionId());
        WritableMap connectionInfo = Arguments.createMap();
        connectionInfo.putString("connectionId", connection.getConnectionId());
        connectionInfo.putString("data", connection.getData());
        connectionInfo.putString("creationTime", connection.getCreationTime().toString());
        eventData.putMap("connection", connectionInfo);
        emitOnConnectionCreated(eventData);
    }

    @Override
    public void onConnectionDestroyed(Session session, Connection connection) {
        WritableMap eventData = Arguments.createMap();
        eventData.putString("sessionId", session.getSessionId());
        WritableMap connectionInfo = Arguments.createMap();
        connectionInfo.putString("connectionId", connection.getConnectionId());
        connectionInfo.putString("data", connection.getData());
        connectionInfo.putString("creationTime", connection.getCreationTime().toString());
        eventData.putMap("connection", connectionInfo);
        emitOnConnectionDestroyed(eventData);
    }

    @Override
    public void onMuteForced(Session session, MuteForcedInfo muteForcedInfo) {
        WritableMap info = Arguments.createMap();
        info.putBoolean("active", muteForcedInfo.getActive());
        emitOnMuteForced(info);
    }

    @Override
    public void onReconnecting(Session session) {
        emitOnSessionReconnecting(null);
    }

    @Override
    public void onReconnected(Session session) {
        emitOnSessionReconnected(null);
    }

    @Override
    public void onStreamHasCaptionsChanged(Session session, Stream stream, boolean hasCaptions) {
        WritableMap eventData = EventUtils.prepareStreamPropertyChangedEventData(
                "hasCaptions", !hasCaptions, hasCaptions, stream, session);
        emitOnStreamPropertyChanged(eventData);
    }

    @Override
    public void onStreamHasAudioChanged(Session session, Stream stream, boolean hasAudio) {
        WritableMap eventData = EventUtils.prepareStreamPropertyChangedEventData(
                "hasAudio", !hasAudio, hasAudio, stream, session);
        emitOnStreamPropertyChanged(eventData);
    }

    @Override
    public void onStreamHasVideoChanged(Session session, Stream stream, boolean hasVideo) {
        WritableMap eventData = EventUtils.prepareStreamPropertyChangedEventData(
                "hasVideo", !hasVideo, hasVideo, stream, session);
        emitOnStreamPropertyChanged(eventData);
    }

    @Override
    public void onStreamVideoDimensionsChanged(Session session, Stream stream, int width, int height) {
        ConcurrentHashMap<String, Stream> mSubscriberStreams = sharedState.getSubscriberStreams();
        Stream mStream = mSubscriberStreams.get(stream.getStreamId());
        WritableMap oldVideoDimensions = Arguments.createMap();
        if (mStream != null) {
            oldVideoDimensions.putInt("height", mStream.getVideoHeight());
            oldVideoDimensions.putInt("width", mStream.getVideoWidth());
        }
        WritableMap newVideoDimensions = Arguments.createMap();
        newVideoDimensions.putInt("height", height);
        newVideoDimensions.putInt("width", width);
        WritableMap eventData = EventUtils.prepareStreamPropertyChangedEventData(
                "videoDimensions", oldVideoDimensions, newVideoDimensions, stream, session);
        emitOnStreamPropertyChanged(eventData);
    }

    @Override
    public void onStreamVideoTypeChanged(Session session, Stream stream, Stream.StreamVideoType streamVideoType) {
        ConcurrentHashMap<String, Stream> mSubscriberStreams = sharedState.getSubscriberStreams();
        String oldVideoType = stream.getStreamVideoType().toString();
        WritableMap eventData = EventUtils.prepareStreamPropertyChangedEventData(
                "videoType", oldVideoType, streamVideoType.toString(), stream, session);
        emitOnStreamPropertyChanged(eventData);
    }

    @Override
    public void onActivityCreated(@NonNull Activity activity, @Nullable Bundle bundle) {

    }

    @Override
    public void onActivityStarted(@NonNull Activity activity) {

    }

    @Override
    public void onActivityResumed(@NonNull Activity activity) {

    }

    @Override
    public void onActivityPaused(@NonNull Activity activity) {

    }

    @Override
    public void onActivityStopped(@NonNull Activity activity) {

    }

    @Override
    public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle bundle) {

    }

    @Override
    public void onActivityDestroyed(@NonNull Activity activity) {

    }
}
