package com.opentokreactnative;

/**
 * Created by manik on 1/29/18.
 */

import android.util.Log;
import android.widget.FrameLayout;
import android.support.annotation.Nullable;
import android.view.View;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.UiThreadUtil;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableArray;

import com.opentok.android.Session;
import com.opentok.android.Connection;
import com.opentok.android.Publisher;
import com.opentok.android.PublisherKit;
import com.opentok.android.Stream;
import com.opentok.android.OpentokError;
import com.opentok.android.Subscriber;
import com.opentok.android.SubscriberKit;
import com.opentokreactnative.utils.EventUtils;
import com.opentokreactnative.utils.Utils;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.ArrayList;

public class OTSessionManager extends ReactContextBaseJavaModule
        implements Session.SessionListener,
        PublisherKit.PublisherListener,
        PublisherKit.AudioLevelListener,
        SubscriberKit.SubscriberListener,
        Session.SignalListener,
        Session.ConnectionListener,
        Session.ReconnectionListener,
        Session.ArchiveListener,
        Session.StreamPropertiesListener,
        SubscriberKit.AudioLevelListener,
        SubscriberKit.AudioStatsListener,
        SubscriberKit.VideoStatsListener,
        SubscriberKit.VideoListener,
        SubscriberKit.StreamListener{

    private Callback connectCallback;
    private Callback disconnectCallback;
    private int connectionStatus = 0;
    private ArrayList<String> jsEvents = new ArrayList<String>();
    private ArrayList<String> componentEvents = new ArrayList<String>();
    private static final String TAG = "OTRN";
    private final String sessionPreface = "session:";
    private final String publisherPreface = "publisher:";
    private final String subscriberPreface = "subscriber:";
    private Boolean logLevel = false;
    public OTRN sharedState;

    public OTSessionManager(ReactApplicationContext reactContext) {

        super(reactContext);
        sharedState = OTRN.getSharedState();

    }

    @ReactMethod
    public void initSession(String apiKey, String sessionId) {

        Session mSession = new Session.Builder(this.getReactApplicationContext(), apiKey, sessionId).build();
        mSession.setSessionListener(this);
        mSession.setSignalListener(this);
        mSession.setConnectionListener(this);
        mSession.setReconnectionListener(this);
        mSession.setArchiveListener(this);
        mSession.setStreamPropertiesListener(this);
        sharedState.setSession(mSession);
    }

    @ReactMethod
    public void connect(String token, Callback callback) {

        Session mSession = sharedState.getSession();
        mSession.connect(token);
        connectCallback = callback;
    }

    @ReactMethod
    public void initPublisher(String publisherId, ReadableMap properties, Callback callback) {

        String name = properties.getString("name");
        Boolean videoTrack = properties.getBoolean("videoTrack");
        Boolean audioTrack = properties.getBoolean("audioTrack");
        String cameraPosition = properties.getString("cameraPosition");
        Boolean audioFallbackEnabled = properties.getBoolean("audioFallbackEnabled");
        int audioBitrate = properties.getInt("audioBitrate");
        String frameRate = "FPS_" + properties.getInt("frameRate");
        String resolution = properties.getString("resolution");
        Boolean publishAudio = properties.getBoolean("publishAudio");
        Boolean publishVideo = properties.getBoolean("publishVideo");
        String videoSource = properties.getString("videoSource");
        Publisher mPublisher = null;
        if (videoSource.equals("screen")) {
            View view = getCurrentActivity().getWindow().getDecorView().getRootView();
            OTScreenCapturer capturer = new OTScreenCapturer(view);
            mPublisher = new Publisher.Builder(this.getReactApplicationContext())
                                        .audioTrack(audioTrack)
                                        .videoTrack(videoTrack)
                                        .name(name)
                                        .audioBitrate(audioBitrate)
                                        .resolution(Publisher.CameraCaptureResolution.valueOf(resolution))
                                        .frameRate(Publisher.CameraCaptureFrameRate.valueOf(frameRate))
                                        .capturer(capturer)
                                        .build();
            mPublisher.setPublisherVideoType(PublisherKit.PublisherKitVideoType.PublisherKitVideoTypeScreen);
        } else {
            mPublisher = new Publisher.Builder(this.getReactApplicationContext())
                                        .audioTrack(audioTrack)
                                        .videoTrack(videoTrack)
                                        .name(name)
                                        .audioBitrate(audioBitrate)
                                        .resolution(Publisher.CameraCaptureResolution.valueOf(resolution))
                                        .frameRate(Publisher.CameraCaptureFrameRate.valueOf(frameRate))
                                        .build();
            if (cameraPosition.equals("back")) {
                mPublisher.cycleCamera();
            }
        }
        mPublisher.setPublisherListener(this);
        mPublisher.setAudioLevelListener(this);
        mPublisher.setAudioFallbackEnabled(audioFallbackEnabled);
        mPublisher.setPublishVideo(publishVideo);
        mPublisher.setPublishAudio(publishAudio);
        ConcurrentHashMap<String, Publisher> mPublishers = sharedState.getPublishers();
        mPublishers.put(publisherId, mPublisher);
        callback.invoke();
    }

    @ReactMethod
    public void publish(String publisherId, Callback callback) {

        Session mSession = sharedState.getSession();
        ConcurrentHashMap<String, Publisher> mPublishers = sharedState.getPublishers();
        Publisher mPublisher = mPublishers.get(publisherId);
        if (mSession != null && mPublisher != null) {
            mSession.publish(mPublisher);
            callback.invoke();
        } else {
            callback.invoke("There was an error publishing");
        }

    }

    @ReactMethod
    public void subscribeToStream(String streamId, ReadableMap properties, Callback callback) {

        ConcurrentHashMap<String, Stream> mSubscriberStreams = sharedState.getSubscriberStreams();
        ConcurrentHashMap<String, Subscriber> mSubscribers = sharedState.getSubscribers();
        Session mSession = sharedState.getSession();
        Stream stream = mSubscriberStreams.get(streamId);
        Subscriber mSubscriber = new Subscriber.Builder(getReactApplicationContext(), stream).build();
        mSubscriber.setSubscriberListener(this);
        mSubscriber.setAudioLevelListener(this);
        mSubscriber.setAudioStatsListener(this);
        mSubscriber.setVideoStatsListener(this);
        mSubscriber.setVideoListener(this);
        mSubscriber.setStreamListener(this);        
        mSubscriber.setSubscribeToAudio(properties.getBoolean("subscribeToAudio"));
        mSubscriber.setSubscribeToVideo(properties.getBoolean("subscribeToVideo"));
        mSubscribers.put(streamId, mSubscriber);
        mSession.subscribe(mSubscriber);
        callback.invoke();

    }

    @ReactMethod
    public void removeSubscriber(final String streamId, final Callback callback) {

        UiThreadUtil.runOnUiThread(new Runnable() {
            @Override
            public void run() {
     
                String mStreamId = streamId;
                Callback mCallback = callback;
                ConcurrentHashMap<String, Subscriber> mSubscribers = sharedState.getSubscribers();
                ConcurrentHashMap<String, Stream> mSubscriberStreams = sharedState.getSubscriberStreams();
                ConcurrentHashMap<String, FrameLayout> mSubscriberViewContainers = sharedState.getSubscriberViewContainers();
                Subscriber mSubscriber = mSubscribers.get(mStreamId);
                FrameLayout mSubscriberViewContainer = mSubscriberViewContainers.get(mStreamId);
                if (mSubscriberViewContainer != null) {
                    mSubscriberViewContainer.removeAllViews();
                }
                mSubscriberViewContainers.remove(mStreamId);
                mSubscriber.destroy();
                mSubscribers.remove(mStreamId);
                mSubscriberStreams.remove(mStreamId);
                mCallback.invoke();

            }
          });
    }

    @ReactMethod
    public void disconnectSession(Callback callback) {

        Session mSession = sharedState.getSession();
        if (mSession != null) {
            mSession.disconnect();
        }
        sharedState.setSession(null);
        disconnectCallback = callback;
    }

    @ReactMethod
    public void publishAudio(String publisherId, Boolean publishAudio) {

        ConcurrentHashMap<String, Publisher> mPublishers = sharedState.getPublishers();
        Publisher mPublisher = mPublishers.get(publisherId);
        mPublisher.setPublishAudio(publishAudio);
    }

    @ReactMethod
    public void publishVideo(String publisherId, Boolean publishVideo) {

        ConcurrentHashMap<String, Publisher> mPublishers = sharedState.getPublishers();
        Publisher mPublisher = mPublishers.get(publisherId);
        mPublisher.setPublishVideo(publishVideo);
    }

    @ReactMethod
    public void subscribeToAudio(String streamId, Boolean subscribeToAudio) {

        ConcurrentHashMap<String, Subscriber> mSubscribers = sharedState.getSubscribers();
        Subscriber mSubscriber = mSubscribers.get(streamId);
        if (mSubscriber != null) {
            mSubscriber.setSubscribeToAudio(subscribeToAudio);
        }
    }

    @ReactMethod
    public void subscribeToVideo(String streamId, Boolean subscribeToVideo) {

        ConcurrentHashMap<String, Subscriber> mSubscribers = sharedState.getSubscribers();
        Subscriber mSubscriber = mSubscribers.get(streamId);
        if (mSubscriber != null) {
            mSubscriber.setSubscribeToVideo(subscribeToVideo);
        }
    }

    @ReactMethod
    public void changeCameraPosition(String publisherId, String cameraPosition) {

        ConcurrentHashMap<String, Publisher> mPublishers = sharedState.getPublishers();
        Publisher mPublisher = mPublishers.get(publisherId);
        mPublisher.cycleCamera();
        Log.i(TAG, "Changing camera to " + cameraPosition);
    }

    @ReactMethod
    public void setNativeEvents(ReadableArray events) {

        for (int i = 0; i < events.size(); i++) {
            jsEvents.add(events.getString(i));
        }
    }

    @ReactMethod
    public void removeNativeEvents(ReadableArray events) {

        for (int i = 0; i < events.size(); i++) {
            jsEvents.remove(events.getString(i));
        }
    }

    @ReactMethod
    public void setJSComponentEvents(ReadableArray events) {

        for (int i = 0; i < events.size(); i++) {
            componentEvents.add(events.getString(i));
        }
    }

    @ReactMethod
    public void removeJSComponentEvents(ReadableArray events) {

        for (int i = 0; i < events.size(); i++) {
            componentEvents.remove(events.getString(i));
        }
    }

    @ReactMethod
    public void sendSignal(ReadableMap signal, Callback callback) {

        Session mSession = sharedState.getSession();
        mSession.sendSignal(signal.getString("type"), signal.getString("data"));
        callback.invoke();
    }

    @ReactMethod
    public void destroyPublisher(final String publisherId, final Callback callback) {

        UiThreadUtil.runOnUiThread(new Runnable() {
            @Override
            public void run() {

                Callback mCallback = callback;
                ConcurrentHashMap<String, Publisher> mPublishers = sharedState.getPublishers();
                Publisher mPublisher = mPublishers.get(publisherId);
                ConcurrentHashMap<String, FrameLayout> mPublisherViewContainers = sharedState.getPublisherViewContainers();
                FrameLayout mPublisherViewContainer = mPublisherViewContainers.get(publisherId);
                Session mSession = sharedState.getSession();
                if (mPublisherViewContainer != null) {
                    mPublisherViewContainer.removeAllViews();
                }
                mPublisherViewContainers.remove(publisherId);
                if (mSession != null) {
                    mSession.unpublish(mPublisher);
                }
                mPublisher.destroy();
                mPublishers.remove(publisherId);
                mCallback.invoke();

            }
        });
    }

    @ReactMethod
    public void getSessionInfo(Callback callback) {

        Session mSession = sharedState.getSession();
        WritableMap sessionInfo = EventUtils.prepareJSSessionMap(mSession);
        sessionInfo.putString("sessionId", mSession.getSessionId());
        sessionInfo.putInt("connectionStatus", getConnectionStatus());
        callback.invoke(sessionInfo);
    }

    @ReactMethod
    public void enableLogs(Boolean logLevel) {
        setLogLevel(logLevel);
    }

    private void setLogLevel(Boolean logLevel) {
        this.logLevel = logLevel;
    }

    private void sendEventMap(ReactContext reactContext, String eventName, @Nullable WritableMap eventData) {

        if (Utils.contains(jsEvents, eventName) || Utils.contains(componentEvents, eventName)) {
            reactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit(eventName, eventData);
        }
    }

    private void sendEventWithString(ReactContext reactContext, String eventName, String eventString) {

        if (Utils.contains(jsEvents, eventName) || Utils.contains(componentEvents, eventName)) {
            reactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit(eventName, eventString);
        }
    }

    private int getConnectionStatus() {

        return this.connectionStatus;
    }

    private void setConnectionStatus(int connectionStatus) {

        this.connectionStatus = connectionStatus;
    }


    private void printLogs(String message) {
        if (this.logLevel) {
            Log.i(TAG, message);
        }
    }

    @Override
    public String getName() {

        return this.getClass().getSimpleName();
    }

    @Override
    public void onError(Session session, OpentokError opentokError) {

        if (Utils.didConnectionFail(opentokError)) {
            setConnectionStatus(6);
        }
        WritableMap errorInfo = EventUtils.prepareJSErrorMap(opentokError);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onError", errorInfo);
        printLogs("There was an error");
    }

    @Override
    public void onDisconnected(Session session) {

        setConnectionStatus(0);
        if (disconnectCallback != null) {
            disconnectCallback.invoke();
        }
        WritableMap sessionInfo = EventUtils.prepareJSSessionMap(session);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onDisconnected", sessionInfo);
        printLogs("onDisconnected: Disconnected from session: " + session.getSessionId());
    }

    @Override
    public void onStreamReceived(Session session, Stream stream) {

        ConcurrentHashMap<String, Stream> mSubscriberStreams = sharedState.getSubscriberStreams();
        mSubscriberStreams.put(stream.getStreamId(), stream);
        WritableMap streamInfo = EventUtils.prepareJSStreamMap(stream);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onStreamReceived", streamInfo);
        printLogs("onStreamReceived: New Stream Received " + stream.getStreamId() + " in session: " + session.getSessionId());

    }

    @Override
    public void onConnected(Session session) {

        setConnectionStatus(1);
        connectCallback.invoke();
        WritableMap sessionInfo = EventUtils.prepareJSSessionMap(session);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onConnected", sessionInfo);
        connectCallback = null;
        printLogs("onConnected: Connected to session: "+session.getSessionId());
    }

    @Override
    public void onReconnected(Session session) {

        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onReconnected", null);
        printLogs("Reconnected");
    }

    @Override
    public void onReconnecting(Session session) {

        setConnectionStatus(3);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onReconnecting", null);
        printLogs("Reconnecting");
    }

    @Override
    public void onArchiveStarted(Session session, String id, String name) {

        WritableMap archiveInfo = Arguments.createMap();
        archiveInfo.putString("archiveId", id);
        archiveInfo.putString("name", name);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onArchiveStarted", archiveInfo);
        printLogs("Archive Started: " + id);
    }

    @Override
    public void onArchiveStopped(Session session, String id) {

        WritableMap archiveInfo = Arguments.createMap();
        archiveInfo.putString("archiveId", id);
        archiveInfo.putString("name", "");
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onArchiveStopped", archiveInfo);
        printLogs("Archive Stopped: " + id);
    }
    @Override
    public void onConnectionCreated(Session session, Connection connection) {

        WritableMap connectionInfo = EventUtils.prepareJSConnectionMap(connection);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onConnectionCreated", connectionInfo);
        printLogs("onConnectionCreated: Connection Created: "+connection.getConnectionId());
    }

    @Override
    public void onConnectionDestroyed(Session session, Connection connection) {

        WritableMap connectionInfo = EventUtils.prepareJSConnectionMap(connection);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onConnectionDestroyed", connectionInfo);
        printLogs("onConnectionDestroyed: Connection Destroyed: "+connection.getConnectionId());
    }
    @Override
    public void onStreamDropped(Session session, Stream stream) {

        WritableMap streamInfo = EventUtils.prepareJSStreamMap(stream);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onStreamDropped", streamInfo);
        printLogs("onStreamDropped: Stream Dropped: "+stream.getStreamId() +" in session: "+session.getSessionId());
    }

    @Override
    public void onStreamCreated(PublisherKit publisherKit, Stream stream) {

        String publisherId = Utils.getPublisherId(publisherKit);
        if (publisherId.length() > 0) {
            String event = publisherId + ":" + publisherPreface + "onStreamCreated";;
            WritableMap streamInfo = EventUtils.prepareJSStreamMap(stream);
            sendEventMap(this.getReactApplicationContext(), event, streamInfo);
        }
        printLogs("onStreamCreated: Publisher Stream Created. Own stream "+stream.getStreamId());

    }

    @Override
    public void onStreamDestroyed(PublisherKit publisherKit, Stream stream) {

        String publisherId = Utils.getPublisherId(publisherKit);
        String event = publisherId + ":" + publisherPreface + "onStreamDestroyed";
        if (publisherId.length() > 0) {
            WritableMap streamInfo = EventUtils.prepareJSStreamMap(stream);
            sendEventMap(this.getReactApplicationContext(), event, streamInfo);
        }
        printLogs("onStreamDestroyed: Publisher Stream Destroyed. Own stream "+stream.getStreamId());
    }

    @Override
    public void onError(PublisherKit publisherKit, OpentokError opentokError) {

        String publisherId = Utils.getPublisherId(publisherKit);
        if (publisherId.length() > 0) {
            String event = publisherId + ":" + publisherPreface +  "onError";
            WritableMap errorInfo = EventUtils.prepareJSErrorMap(opentokError);
            sendEventMap(this.getReactApplicationContext(), event, errorInfo);
        }
        printLogs("onError: "+opentokError.getErrorDomain() + " : " +
                opentokError.getErrorCode() +  " - "+opentokError.getMessage());
    }

    @Override
    public void onAudioLevelUpdated(PublisherKit publisher, float audioLevel) {

        String publisherId = Utils.getPublisherId(publisher);
        if (publisherId.length() > 0) {
            String event = publisherId + ":" + publisherPreface + "onAudioLevelUpdated";
            sendEventWithString(this.getReactApplicationContext(), event, String.valueOf(audioLevel));
        }
    }

    @Override
    public void onConnected(SubscriberKit subscriberKit) {

        String streamId = Utils.getStreamIdBySubscriber(subscriberKit);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            sendEventMap(this.getReactApplicationContext(), subscriberPreface +  "onConnected", subscriberInfo);
        }
        printLogs("onConnected: Subscriber connected. Stream: "+subscriberKit.getStream().getStreamId());
    }

    @Override
    public void onDisconnected(SubscriberKit subscriberKit) {

        String streamId = Utils.getStreamIdBySubscriber(subscriberKit);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            sendEventMap(this.getReactApplicationContext(), subscriberPreface +  "onDisconnected", subscriberInfo);
        }
        printLogs("onDisconnected: Subscriber disconnected. Stream: "+subscriberKit.getStream().getStreamId());
    }

    @Override
    public void onReconnected(SubscriberKit subscriberKit) {

        String streamId = Utils.getStreamIdBySubscriber(subscriberKit);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            sendEventMap(this.getReactApplicationContext(), subscriberPreface +  "onReconnected", subscriberInfo);
        }
        printLogs("onReconnected: Subscriber reconnected. Stream: "+subscriberKit.getStream().getStreamId());
    }

    @Override
    public void onError(SubscriberKit subscriberKit, OpentokError opentokError) {

        String streamId = Utils.getStreamIdBySubscriber(subscriberKit);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            subscriberInfo.putMap("error", EventUtils.prepareJSErrorMap(opentokError));
            sendEventMap(this.getReactApplicationContext(), subscriberPreface +  "onError", subscriberInfo);
        }
        printLogs("onError: "+opentokError.getErrorDomain() + " : " +
                opentokError.getErrorCode() +  " - "+opentokError.getMessage());

    }

    @Override
    public void onSignalReceived(Session session, String type, String data, Connection connection) {

        WritableMap signalInfo = Arguments.createMap();
        signalInfo.putString("type", type);
        signalInfo.putString("data", data);
        signalInfo.putString("connectionId", connection.getConnectionId());
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onSignalReceived", signalInfo);
        printLogs("onSignalReceived: Data: " + data + " Type: " + type);
    }

    @Override
    public void onAudioStats(SubscriberKit subscriber, SubscriberKit.SubscriberAudioStats stats) {

        String streamId = Utils.getStreamIdBySubscriber(subscriber);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            subscriberInfo.putMap("audioStats", EventUtils.prepareAudioNetworkStats(stats));
            sendEventMap(this.getReactApplicationContext(), subscriberPreface +  "onAudioStats", subscriberInfo);
        }
    }

    @Override
    public void onVideoStats(SubscriberKit subscriber, SubscriberKit.SubscriberVideoStats stats) {

        String streamId = Utils.getStreamIdBySubscriber(subscriber);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            subscriberInfo.putMap("videoStats", EventUtils.prepareVideoNetworkStats(stats));
            sendEventMap(this.getReactApplicationContext(), subscriberPreface + "onVideoStats", subscriberInfo);
        }
    }

    @Override
    public void onAudioLevelUpdated(SubscriberKit subscriber, float audioLevel) {

        String streamId = Utils.getStreamIdBySubscriber(subscriber);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            subscriberInfo.putString("audioLevel", String.valueOf(audioLevel));
            sendEventMap(this.getReactApplicationContext(), subscriberPreface + "onAudioLevelUpdated", subscriberInfo);
        }
    }

    @Override
    public void onVideoDisabled(SubscriberKit subscriber, String reason) {

        String streamId = Utils.getStreamIdBySubscriber(subscriber);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            subscriberInfo.putString("reason", reason);
            sendEventMap(this.getReactApplicationContext(), subscriberPreface + "onVideoDisabled", subscriberInfo);
        }
        printLogs("onVideoDisabled " + reason);
    }

    @Override
    public void onVideoEnabled(SubscriberKit subscriber, String reason) {

        String streamId = Utils.getStreamIdBySubscriber(subscriber);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            subscriberInfo.putString("reason", reason);
            sendEventMap(this.getReactApplicationContext(), subscriberPreface + "onVideoEnabled", subscriberInfo);
        }
        printLogs("onVideoEnabled " + reason);
    }

    @Override
    public void onVideoDisableWarning(SubscriberKit subscriber) {

        String streamId = Utils.getStreamIdBySubscriber(subscriber);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            sendEventMap(this.getReactApplicationContext(), subscriberPreface + "onVideoDisableWarning", subscriberInfo);
        }
        printLogs("onVideoDisableWarning");
    }

    @Override
    public void onVideoDisableWarningLifted(SubscriberKit subscriber) {

        String streamId = Utils.getStreamIdBySubscriber(subscriber);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            sendEventMap(this.getReactApplicationContext(), subscriberPreface + "onVideoDisableWarningLifted", subscriberInfo);
        }
        printLogs("onVideoDisableWarningLifted");
    }

    @Override
    public void onVideoDataReceived(SubscriberKit subscriber) {

        String streamId = Utils.getStreamIdBySubscriber(subscriber);
        if (streamId.length() > 0) {
            ConcurrentHashMap<String, Stream> streams = sharedState.getSubscriberStreams();
            Stream mStream = streams.get(streamId);
            WritableMap subscriberInfo = Arguments.createMap();
            subscriberInfo.putMap("stream", EventUtils.prepareJSStreamMap(mStream));
            sendEventMap(this.getReactApplicationContext(), subscriberPreface + "onVideoDataReceived", subscriberInfo);
        }
    }

    @Override
    public void onStreamHasAudioChanged(Session session, Stream stream, boolean Audio) {

        WritableMap eventData = EventUtils.prepareStreamPropertyChangedEventData("hasAudio", !Audio, Audio, stream);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onStreamPropertyChanged", eventData);
        printLogs("onStreamHasAudioChanged");
    }
    @Override
    public void onStreamHasVideoChanged(Session session, Stream stream, boolean Video) {

        WritableMap eventData = EventUtils.prepareStreamPropertyChangedEventData("hasVideo", !Video, Video, stream);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onStreamPropertyChanged", eventData);
        printLogs("onStreamHasVideoChanged");
    }

    @Override
    public void onStreamVideoDimensionsChanged(Session session, Stream stream, int width, int height) {

        ConcurrentHashMap<String, Stream> mSubscriberStreams = sharedState.getSubscriberStreams();
        Stream mStream = mSubscriberStreams.get(stream.getStreamId());
        WritableMap oldVideoDimensions = Arguments.createMap();
        if ( mStream != null ){
            oldVideoDimensions.putInt("height", mStream.getVideoHeight());
            oldVideoDimensions.putInt("width", mStream.getVideoWidth());
        }
        WritableMap newVideoDimensions = Arguments.createMap();
        newVideoDimensions.putInt("height", height);
        newVideoDimensions.putInt("width", width);
        WritableMap eventData = EventUtils.prepareStreamPropertyChangedEventData("videoDimensions", oldVideoDimensions, newVideoDimensions, stream);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onStreamPropertyChanged", eventData);
        printLogs("onStreamVideoDimensionsChanged");

    }

    @Override
    public void onStreamVideoTypeChanged(Session session, Stream stream, Stream.StreamVideoType videoType) {

        ConcurrentHashMap<String, Stream> mSubscriberStreams = sharedState.getSubscriberStreams();
        Stream mStream = mSubscriberStreams.get(stream.getStreamId());
        String oldVideoType = stream.getStreamVideoType().toString();
        WritableMap eventData = EventUtils.prepareStreamPropertyChangedEventData("videoType", oldVideoType, videoType.toString(), stream);
        sendEventMap(this.getReactApplicationContext(), sessionPreface + "onStreamPropertyChanged", eventData);
        printLogs("onStreamVideoTypeChanged");
    }

}
