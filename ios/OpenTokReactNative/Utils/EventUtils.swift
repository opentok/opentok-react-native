//
//  EventUtils.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 11/3/18.
//  Copyright © 2018 TokBox Inc. All rights reserved.
//

import Foundation

class EventUtils {
    
    static var sessionPreface: String = "session:";
    static var publisherPreface: String = "publisher:";
    static var subscriberPreface: String = "subscriber:";
    
    static func prepareJSConnectionEventData(_ connection: OTConnection) -> Dictionary<String, Any> {
        var connectionInfo: Dictionary<String, Any> = [:];
        guard connection != nil else { return connectionInfo }
        connectionInfo["connectionId"] = connection.connectionId;
        connectionInfo["creationTime"] = convertDateToString(connection.creationTime);
        connectionInfo["data"] = connection.data;
        return connectionInfo;
    }
    
    static func prepareJSStreamEventData(_ stream: OTStream) -> Dictionary<String, Any> {
        var streamInfo: Dictionary<String, Any> = [:];
        guard OTRN.sharedState.sessions[stream.session.sessionId] != nil else { return streamInfo }
        streamInfo["streamId"] = stream.streamId;
        streamInfo["name"] = stream.name;
        streamInfo["connectionId"] = stream.connection.connectionId;
        streamInfo["connection"] = prepareJSConnectionEventData(stream.connection);
        streamInfo["hasAudio"] = stream.hasAudio;
        streamInfo["sessionId"] = stream.session.sessionId;
        streamInfo["hasVideo"] = stream.hasVideo;
        streamInfo["creationTime"] = convertDateToString(stream.creationTime);
        streamInfo["height"] = stream.videoDimensions.height;
        streamInfo["width"] = stream.videoDimensions.width;
        streamInfo["videoType"] = stream.videoType == OTStreamVideoType.screen ? "screen" : "camera"
        return streamInfo;
    }
    
    static func prepareJSErrorEventData(_ error: OTError) -> Dictionary<String, Any> {
        var errorInfo: Dictionary<String, Any> = [:];
        errorInfo["code"] = error.code;
        errorInfo["message"] = error.localizedDescription;
        return errorInfo;
    }
    
    static func prepareStreamPropertyChangedEventData(_ changedProperty: String, oldValue: Any, newValue: Any, stream: Dictionary<String, Any>) -> Dictionary<String, Any> {
        var streamPropertyEventData: Dictionary<String, Any> = [:];
        streamPropertyEventData["oldValue"] = oldValue;
        streamPropertyEventData["newValue"] = newValue;
        streamPropertyEventData["stream"] = stream;
        streamPropertyEventData["changedProperty"] = changedProperty;
        return streamPropertyEventData
    }

    static func preparePublisherRtcStats(_ rtcStatsReport: [OTPublisherRtcStats]) -> [Dictionary<String, Any>] {
        var statsArray:[Dictionary<String, Any>] = [];
        for value in rtcStatsReport {
            var stats:Dictionary<String, Any> = [:];
            stats["connectionId"] = value.connectionId;
            stats["jsonArrayOfReports"] = value.jsonArrayOfReports;
            statsArray.append(stats);
        }
        return statsArray;
    }

    static func preparePublisherVideoNetworkStats(_ videoStats: [OTPublisherKitVideoNetworkStats]) -> [Dictionary<String, Any>] {
        var statsArray:[Dictionary<String, Any>] = [];
        for value in videoStats {
            var stats: Dictionary<String, Any> = [:];
            stats["connectionId"] = value.connectionId;
            stats["subscriberId"] = value.subscriberId;
            stats["videoPacketsLost"] = value.videoPacketsLost;
            stats["videoBytesSent"] = value.videoBytesSent;
            stats["videoPacketsSent"] = value.videoPacketsSent;
            stats["timestamp"] = value.timestamp;
            statsArray.append(stats);
        }
        return statsArray;
    }

    static func preparePublisherAudioNetworkStats(_ audioStats: [OTPublisherKitAudioNetworkStats]) -> [Dictionary<String, Any>] {
        var statsArray:[Dictionary<String, Any>] = [];
        for value in audioStats {
            var stats: Dictionary<String, Any> = [:];
            stats["connectionId"] = value.connectionId;
            stats["subscriberId"] = value.subscriberId;
            stats["audioPacketsLost"] = value.audioPacketsLost;
            stats["audioPacketsSent"] = value.audioPacketsSent;
            stats["audioBytesSent"] = value.audioBytesSent;
            stats["timestamp"] = value.timestamp;
            statsArray.append(stats);
        }
        return statsArray;
    }
    
    static func prepareSubscriberVideoNetworkStatsEventData(_ videoStats: OTSubscriberKitVideoNetworkStats) -> Dictionary<String, Any> {
        var videoStatsEventData: Dictionary<String, Any> = [:];
        videoStatsEventData["videoPacketsLost"] = videoStats.videoPacketsLost;
        videoStatsEventData["videoBytesReceived"] = videoStats.videoBytesReceived;
        videoStatsEventData["videoPacketsReceived"] = videoStats.videoPacketsReceived;
        videoStatsEventData["timestamp"] = videoStats.timestamp;
        return videoStatsEventData;
    }
    
    static func prepareSubscriberAudioNetworkStatsEventData(_ audioStats: OTSubscriberKitAudioNetworkStats) -> Dictionary<String, Any> {
        var audioStatsEventData: Dictionary<String, Any> = [:];
        audioStatsEventData["audioPacketsLost"] = audioStats.audioPacketsLost;
        audioStatsEventData["audioBytesReceived"] = audioStats.audioBytesReceived;
        audioStatsEventData["audioPacketsReceived"] = audioStats.audioPacketsReceived;
        audioStatsEventData["timestamp"] = audioStats.timestamp;
        return audioStatsEventData;
    }
    
    static func prepareJSSessionEventData(_ session: OTSession) -> Dictionary<String, Any> {
        var sessionInfo: Dictionary<String, Any> = [:];
        sessionInfo["sessionId"] = session.sessionId;
        guard let connection = session.connection else { return sessionInfo };
        sessionInfo["connection"] = prepareJSConnectionEventData(connection);
        return sessionInfo;
    }
    
    static func getSupportedEvents() -> [String] {
        return [
            "\(sessionPreface)streamCreated",
            "\(sessionPreface)streamDestroyed",
            "\(sessionPreface)sessionDidConnect",
            "\(sessionPreface)sessionDidDisconnect",
            "\(sessionPreface)connectionCreated",
            "\(sessionPreface)connectionDestroyed",
            "\(sessionPreface)didFailWithError",
            "\(publisherPreface)streamCreated",
            "\(sessionPreface)signal",
            "\(sessionPreface)muteForced",
            "\(publisherPreface)streamDestroyed",
            "\(publisherPreface)didFailWithError",
            "\(publisherPreface)audioLevelUpdated",
            "\(publisherPreface)rtcStatsReport",
            "\(publisherPreface)muteForced",
            "\(publisherPreface)videoEnabled",
            "\(publisherPreface)videoDisabled",
            "\(publisherPreface)videoDisableWarning",
            "\(publisherPreface)videoDisableWarningLifted",
            "\(subscriberPreface)subscriberDidConnect",
            "\(subscriberPreface)subscriberDidDisconnect",
            "\(subscriberPreface)didFailWithError",
            "\(subscriberPreface)videoNetworkStatsUpdated",
            "\(subscriberPreface)audioNetworkStatsUpdated",
            "\(subscriberPreface)audioLevelUpdated",
            "\(subscriberPreface)rtcStatsReport",
            "\(subscriberPreface)subscriberVideoEnabled",
            "\(subscriberPreface)subscriberVideoDisabled",
            "\(subscriberPreface)subscriberVideoDisableWarning",
            "\(subscriberPreface)subscriberVideoDisableWarningLifted",
            "\(subscriberPreface)subscriberVideoDataReceived",
            "\(sessionPreface)archiveStartedWithId",
            "\(sessionPreface)archiveStoppedWithId",
            "\(sessionPreface)sessionDidBeginReconnecting",
            "\(sessionPreface)sessionDidReconnect",
            "\(sessionPreface)streamPropertyChanged",
            "\(subscriberPreface)subscriberDidReconnect",
            "\(subscriberPreface)subscriberCaptionReceived"
        ];
    }
    
    static func convertDateToString(_ creationTime: Date) -> String {
        let dateFormatter: DateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss";
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC");
        return dateFormatter.string(from:creationTime);
    }

    static func createErrorMessage(_ message: String) -> Dictionary<String, String> {
        var errorInfo: Dictionary<String, String> = [:]
        errorInfo["message"] = message
        return errorInfo
    }
    
}
