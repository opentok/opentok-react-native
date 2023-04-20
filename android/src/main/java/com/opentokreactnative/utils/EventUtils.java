package com.opentokreactnative.utils;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.opentok.android.Connection;
import com.opentok.android.MediaUtils;
import com.opentok.android.OpentokError;
import com.opentok.android.Session;
import com.opentok.android.Stream;
import com.opentok.android.SubscriberKit;
import com.opentok.android.PublisherKit;

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

    public static WritableMap prepareJSStreamMap(Stream stream, Session session) {

        WritableMap streamInfo = Arguments.createMap();
        if (stream != null) {
            streamInfo.putString("streamId", stream.getStreamId());
            streamInfo.putInt("height", stream.getVideoHeight());
            streamInfo.putInt("width", stream.getVideoWidth());
            streamInfo.putString("creationTime", stream.getCreationTime().toString());
            streamInfo.putString("connectionId", stream.getConnection().getConnectionId());
            streamInfo.putString("sessionId", session.getSessionId());
            streamInfo.putMap("connection", prepareJSConnectionMap(stream.getConnection()));
            streamInfo.putString("name", stream.getName());
            streamInfo.putBoolean("hasAudio", stream.hasAudio());
            streamInfo.putBoolean("hasVideo", stream.hasVideo());
            if (stream.getStreamVideoType().equals(Stream.StreamVideoType.StreamVideoTypeScreen)) {
                streamInfo.putString("videoType", "screen");
            } else {
                streamInfo.putString("videoType", "camera");
            }
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

    public static WritableMap prepareStreamPropertyChangedEventData(String changedProperty, String oldValue, String newValue, Stream stream, Session session) {

        WritableMap streamPropertyEventData = Arguments.createMap();
        streamPropertyEventData.putString("changedProperty", changedProperty);
        streamPropertyEventData.putString("oldValue", oldValue);
        streamPropertyEventData.putString("newValue", newValue);
        streamPropertyEventData.putMap("stream", prepareJSStreamMap(stream, session));
        return streamPropertyEventData;
    }

    public static WritableMap prepareStreamPropertyChangedEventData(String changedProperty, WritableMap oldValue, WritableMap newValue, Stream stream, Session session) {

        WritableMap streamPropertyEventData = Arguments.createMap();
        streamPropertyEventData.putString("changedProperty", changedProperty);
        streamPropertyEventData.putMap("oldValue", oldValue);
        streamPropertyEventData.putMap("newValue", newValue);
        streamPropertyEventData.putMap("stream", prepareJSStreamMap(stream, session));
        return streamPropertyEventData;
    }

    public static WritableMap prepareStreamPropertyChangedEventData(String changedProperty, Boolean oldValue, Boolean newValue, Stream stream, Session session) {

        WritableMap streamPropertyEventData = Arguments.createMap();
        streamPropertyEventData.putString("changedProperty", changedProperty);
        streamPropertyEventData.putBoolean("oldValue", oldValue);
        streamPropertyEventData.putBoolean("newValue", newValue);
        streamPropertyEventData.putMap("stream", prepareJSStreamMap(stream, session));
        return streamPropertyEventData;
    }

    public static WritableMap prepareAudioNetworkStats(SubscriberKit.SubscriberAudioStats stats) {

        WritableMap audioStats = Arguments.createMap();
        audioStats.putInt("audioPacketsLost", stats.audioPacketsLost);
        audioStats.putInt("audioBytesReceived", stats.audioBytesReceived);
        audioStats.putInt("audioPacketsReceived", stats.audioPacketsReceived);
        audioStats.putDouble("timestamp", stats.timeStamp);
        return audioStats;
    }

    public static WritableMap prepareVideoNetworkStats(SubscriberKit.SubscriberVideoStats stats) {

        WritableMap videoStats = Arguments.createMap();
        videoStats.putInt("videoPacketsLost", stats.videoPacketsLost);
        videoStats.putInt("videoBytesReceived", stats.videoBytesReceived);
        videoStats.putInt("videoPacketsReceived", stats.videoPacketsReceived);
        videoStats.putDouble("timestamp", stats.timeStamp);
        return videoStats;
    }

    public static WritableArray preparePublisherRtcStats(PublisherKit.PublisherRtcStats[] stats) {
        WritableArray statsArrayMap = Arguments.createArray();
        for (PublisherKit.PublisherRtcStats stat : stats) {
          WritableMap statMap = Arguments.createMap();
          statMap.putString("connectionId", stat.connectionId);
          statMap.putString("jsonArrayOfReports", stat.jsonArrayOfReports);
          statsArrayMap.pushMap(statMap);
        }
        return statsArrayMap;
    }

    public static WritableArray preparePublisherAudioStats(PublisherKit.PublisherAudioStats[] stats) {
        WritableArray statsArrayMap = Arguments.createArray();
        for (PublisherKit.PublisherAudioStats stat : stats) {
          WritableMap audioStats = Arguments.createMap();
          audioStats.putString("connectionId", stat.connectionId);
          audioStats.putString("subscriberId", stat.subscriberId);
          audioStats.putDouble("audioBytesSent", stat.audioBytesSent);
          audioStats.putDouble("audioPacketsLost", stat.audioPacketsLost);
          audioStats.putDouble("audioPacketsSent", stat.audioPacketsSent);
          audioStats.putDouble("startTime", stat.startTime);
          statsArrayMap.pushMap(audioStats);
        }
        return statsArrayMap;
    }

    public static WritableArray preparePublisherVideoStats(PublisherKit.PublisherVideoStats[] stats) {
        WritableArray statsArrayMap = Arguments.createArray();
        for (PublisherKit.PublisherVideoStats stat : stats) {
          WritableMap videoStats = Arguments.createMap();
          videoStats.putString("connectionId", stat.connectionId);
          videoStats.putString("subscriberId", stat.subscriberId);
          videoStats.putDouble("videoBytesSent", stat.videoBytesSent);
          videoStats.putDouble("videoPacketsLost", stat.videoPacketsLost);
          videoStats.putDouble("videoPacketsSent", stat.videoPacketsSent);
          videoStats.putDouble("startTime", stat.startTime);
          statsArrayMap.pushMap(videoStats);
        }
        return statsArrayMap;
    }

    public static WritableMap prepareMediaCodecsMap(MediaUtils.SupportedCodecs supportedCodecs) {
        WritableMap codecsMap = Arguments.createMap();
        WritableArray videoDecoderCodecsArray = Arguments.createArray();
        WritableArray videoEncoderCodecsArray = Arguments.createArray();
        for (MediaUtils.VideoCodecType decoderCodec : supportedCodecs.videoDecoderCodecs ) {
            if (decoderCodec.equals(MediaUtils.VideoCodecType.VIDEO_CODEC_H264)) {
                videoDecoderCodecsArray.pushString("H.264");
            } else {
                videoDecoderCodecsArray.pushString("VP8");
            }
        }
        for (MediaUtils.VideoCodecType encoderCodec : supportedCodecs.videoEncoderCodecs ) {
            if (encoderCodec.equals(MediaUtils.VideoCodecType.VIDEO_CODEC_H264)) {
                videoEncoderCodecsArray.pushString("H.264");
            } else {
                videoEncoderCodecsArray.pushString("VP8");
            }
        }
        codecsMap.putArray("videoDecoderCodecs", videoDecoderCodecsArray);
        codecsMap.putArray("videoEncoderCodecs", videoEncoderCodecsArray);
        return codecsMap;
    }

    public static WritableMap createError(String message) {

        WritableMap errorInfo = Arguments.createMap();
        errorInfo.putString("message", message);
        return errorInfo;
    }
}
