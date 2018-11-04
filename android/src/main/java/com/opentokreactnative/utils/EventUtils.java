package com.opentokreactnative.utils;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.opentok.android.Connection;
import com.opentok.android.OpentokError;
import com.opentok.android.Session;
import com.opentok.android.Stream;
import com.opentok.android.SubscriberKit;

public final class EventUtils {

    public static WritableMap prepareJSConnectionMap(Connection connection) {

        WritableMap connectionInfo = Arguments.createMap();
        if (connection != null) {
            connectionInfo.putString("connectionId", connection.getConnectionId());
            connectionInfo.putString("creationTime", connection.getCreationTime().toString());
            connectionInfo.putString("data", connection.getData());
        }
        return connectionInfo;
    }

    public static WritableMap prepareJSStreamMap(Stream stream) {

        WritableMap streamInfo = Arguments.createMap();
        if (stream != null) {
            streamInfo.putString("streamId", stream.getStreamId());
            streamInfo.putInt("height", stream.getVideoHeight());
            streamInfo.putInt("width", stream.getVideoWidth());
            streamInfo.putString("creationTime", stream.getCreationTime().toString());
            streamInfo.putString("connectionId", stream.getConnection().getConnectionId());
            streamInfo.putString("name", stream.getName());
            streamInfo.putBoolean("hasAudio", stream.hasAudio());
            streamInfo.putBoolean("hasVideo", stream.hasVideo());
        }
        return streamInfo;
    }

    public static WritableMap prepareJSErrorMap(OpentokError error) {

        WritableMap errorInfo = Arguments.createMap();
        errorInfo.putString("message", error.getMessage());
        errorInfo.putString("code", error.getErrorCode().toString());
        return errorInfo;
    }

    public static WritableMap prepareJSSessionMap(Session session) {

        WritableMap sessionInfo = Arguments.createMap();
        sessionInfo.putString("sessionId", session.getSessionId());
        if (session.getConnection() != null) {
            WritableMap connectionInfo = prepareJSConnectionMap(session.getConnection());
            sessionInfo.putMap("connection", connectionInfo);
        }
        return sessionInfo;
    }

    public static WritableMap prepareStreamPropertyChangedEventData(String changedProperty, String oldValue, String newValue, Stream stream) {

        WritableMap streamPropertyEventData = Arguments.createMap();
        streamPropertyEventData.putString("changedProperty", changedProperty);
        streamPropertyEventData.putString("oldValue", oldValue);
        streamPropertyEventData.putString("newValue", newValue);
        streamPropertyEventData.putMap("stream", prepareJSStreamMap(stream));
        return streamPropertyEventData;
    }

    public static WritableMap prepareStreamPropertyChangedEventData(String changedProperty, WritableMap oldValue, WritableMap newValue, Stream stream) {

        WritableMap streamPropertyEventData = Arguments.createMap();
        streamPropertyEventData.putString("changedProperty", changedProperty);
        streamPropertyEventData.putMap("oldValue", oldValue);
        streamPropertyEventData.putMap("newValue", newValue);
        streamPropertyEventData.putMap("stream", prepareJSStreamMap(stream));
        return streamPropertyEventData;
    }

    public static WritableMap prepareStreamPropertyChangedEventData(String changedProperty, Boolean oldValue, Boolean newValue, Stream stream) {

        WritableMap streamPropertyEventData = Arguments.createMap();
        streamPropertyEventData.putString("changedProperty", changedProperty);
        streamPropertyEventData.putBoolean("oldValue", oldValue);
        streamPropertyEventData.putBoolean("newValue", newValue);
        streamPropertyEventData.putMap("stream", prepareJSStreamMap(stream));
        return streamPropertyEventData;
    }

    public static WritableMap prepareAudioNetworkStats(SubscriberKit.SubscriberAudioStats stats) {

        WritableMap audioStats = Arguments.createMap();
        audioStats.putInt("audioPacketsLost", stats.audioPacketsLost);
        audioStats.putInt("audioBytesReceived", stats.audioBytesReceived);
        audioStats.putInt("audioPacketsReceived", stats.audioPacketsReceived);
        return audioStats;
    }

    public static WritableMap prepareVideoNetworkStats(SubscriberKit.SubscriberVideoStats stats) {

        WritableMap videoStats = Arguments.createMap();
        videoStats.putInt("videoPacketsLost", stats.videoPacketsLost);
        videoStats.putInt("videoBytesReceived", stats.videoBytesReceived);
        videoStats.putInt("videoPacketsReceived", stats.videoPacketsReceived);
        return videoStats;
    }
}
