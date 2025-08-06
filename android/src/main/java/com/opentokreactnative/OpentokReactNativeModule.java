package com.opentokreactnative;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.List;
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
import com.opentok.android.Session.Builder.TransportPolicy;
import com.opentok.android.Session.Builder.IncludeServers;
import com.opentok.android.Session.Builder.IceServer;
import com.opentok.android.Session.SessionOptions;
import com.opentok.android.Session.SessionListener;
import com.opentok.android.Session.SignalListener;
import com.opentok.android.Stream;
import com.opentok.android.Subscriber;
import com.opentokreactnative.utils.EventUtils;
import com.opentokreactnative.utils.Utils;


public class OpentokReactNativeModule extends NativeOpentokSpec implements
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

        final boolean useTextureViews = options.getBoolean("useTextureViews");
        final boolean connectionEventsSuppressed = options.getBoolean("connectionEventsSuppressed");
        final boolean ipWhitelist = options.getBoolean("ipWhitelist");
        final List<IceServer> iceServersList = Utils.sanitizeIceServer(options.getArray("customServers"));
        final IncludeServers includeServers = Utils.sanitizeIncludeServer(options.getString("includeServers"));
        final TransportPolicy transportPolicy = Utils.sanitizeTransportPolicy(options.getString("transportPolicy"));
        final String proxyUrl = options.getString("proxyUrl");
        final String androidOnTop = options.getString("androidOnTop");
        final String androidZOrder = options.getString("androidZOrder");
        final boolean singlePeerConnection = options.getBoolean("enableSinglePeerConnection");
        final boolean sessionMigration = options.getBoolean("sessionMigration");
        ConcurrentHashMap<String, String> androidOnTopMap = sharedState.getAndroidOnTopMap();
        ConcurrentHashMap<String, String> androidZOrderMap = sharedState.getAndroidZOrderMap();

        session = new Session.Builder(context, apiKey, sessionId)
            .sessionOptions(new Session.SessionOptions() {
                @Override
                public boolean useTextureViews() {
                    return useTextureViews;
                }
            })
            .connectionEventsSuppressed(connectionEventsSuppressed)
            .setCustomIceServers(iceServersList, includeServers)
            .setIceRouting(transportPolicy)
            .setIpWhitelist(ipWhitelist)
            .setProxyUrl(proxyUrl)
            .setSinglePeerConnection(singlePeerConnection)
            .setSessionMigration(sessionMigration)
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
        androidOnTopMap.put(sessionId, androidOnTop);
        androidZOrderMap.put(sessionId, androidZOrder);
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
    public void unpublish(String publisherId) {
        ConcurrentHashMap<String, Publisher> publishers = sharedState.getPublishers();
        Publisher publisher = publishers.get(publisherId);
        if (publisher != null) {
            session.unpublish(publisher);
            publishers.remove(publisher);
        }
    }

    @Override
    public void removeSubscriber(String streamId) {
        ConcurrentHashMap<String, Subscriber> subscribers = sharedState.getSubscribers();
        Subscriber subscriber = subscribers.get(streamId);
        if (subscriber != null) {
            session.unsubscribe(subscriber);
            subscribers.remove(subscriber);
        }
    }

    @Override
    public void disableForceMute(String sessionId, Promise promise) {
        ConcurrentHashMap<String, Session> mSessions = sharedState.getSessions();
        Session mSession = mSessions.get(sessionId);
        if (mSession == null) {
            promise.reject("Session not found.");
            return;
        }
        mSession.disableForceMute();
        promise.resolve(true);
    }

    @Override
    public void forceMuteAll(String sessionId, ReadableArray excludedStreamIds, Promise promise) {
        ConcurrentHashMap<String, Session> mSessions = sharedState.getSessions();
        Session mSession = mSessions.get(sessionId);
        ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
        ArrayList<Stream> mExcludedStreams = new ArrayList<Stream>();
        if (mSession == null) {
            promise.reject("Session not found.");
            return;
        }
        for (int i = 0; i < excludedStreamIds.size(); i++) {
            String streamId = excludedStreamIds.getString(i);
            Stream mStream = streams.get(streamId);
            if (mStream == null) {
                promise.reject("Stream not found.");
                continue;
            }
            mExcludedStreams.add(mStream);
        }
        mSession.forceMuteAll(mExcludedStreams);
        promise.resolve(null);
    }

    @Override
    public void forceMuteStream(String sessionId, String streamId, Promise promise) {
        ConcurrentHashMap<String, Session> mSessions = sharedState.getSessions();
        Session mSession = mSessions.get(sessionId);
        ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
        if (mSession == null) {
            promise.reject("Session not found.");
            return;
        }
        Stream mStream = streams.get(streamId);
        if (mStream == null) {
            promise.reject("Stream not found.");
            return;
        }
        mSession.forceMuteStream(mStream);
        promise.resolve(null);
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
        ConcurrentHashMap<String, Session> mSessions = sharedState.getSessions();
        Session mSession = mSessions.get(sessionId);
        if (mSession != null){
            promise.resolve(mSession.reportIssue());
        } else {
            promise.reject("Error connecting to session. Could not find native session instance.");
        }
    }

    @Override
    public void setEncryptionSecret(String sessionId, String secret, Promise promise) {
        ConcurrentHashMap<String, Session> mSessions = sharedState.getSessions();
        Session mSession = mSessions.get(sessionId);
        if (mSession != null) {
            mSession.setEncryptionSecret(secret);
            promise.resolve(null);
        } else {
            promise.reject("There was an error setting the encryption secret. The native session instance could not be found.");
        }
    }

    @Override
    public void onConnected(Session session) {
        WritableMap payload = EventUtils.prepareJSSessionMap(session);
        emitOnSessionConnected(payload);
    }

    @Override
    public void onDisconnected(Session session) {
        WritableMap payload = EventUtils.prepareJSSessionMap(session);
        emitOnSessionDisconnected(payload);
    }

    @Override
    public void onStreamReceived(Session session, Stream stream) {
        sharedState.getSubscriberStreams().put(stream.getStreamId(), stream);
        WritableMap payload = EventUtils.prepareJSStreamMap(stream, session);
        emitOnStreamCreated(payload);
    }

    @Override
    public void onStreamDropped(Session session, Stream stream) {
        WritableMap payload = EventUtils.prepareJSStreamMap(stream, session);
        emitOnStreamDestroyed(payload);
    }

    @Override
    public void onError(Session session, OpentokError opentokError) {
        WritableMap payload = EventUtils.prepareJSErrorMap(opentokError);
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
        WritableMap connectionInfo = EventUtils.prepareJSConnectionMap(
        connection);
        eventData.putMap("connection", connectionInfo);
        emitOnConnectionCreated(eventData);
    }

    @Override
    public void onConnectionDestroyed(Session session, Connection connection) {
        WritableMap eventData = Arguments.createMap();
        eventData.putString("sessionId", session.getSessionId());
        WritableMap connectionInfo = EventUtils.prepareJSConnectionMap(
        connection);
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
