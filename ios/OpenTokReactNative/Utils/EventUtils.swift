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
        guard OTRN.sharedState.session != nil else { return streamInfo }
        streamInfo["streamId"] = stream.streamId;
        streamInfo["name"] = stream.name;
        streamInfo["connectionId"] = stream.connection.connectionId;
        streamInfo["hasAudio"] = stream.hasAudio;
        streamInfo["hasVideo"] = stream.hasVideo;
        streamInfo["creationTime"] = convertDateToString(stream.creationTime);
        streamInfo["height"] = stream.videoDimensions.height;
        streamInfo["width"] = stream.videoDimensions.width;
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
    
    static func prepareSubscriberVideoNetworkStatsEventData(_ videoStats: OTSubscriberKitVideoNetworkStats) -> Dictionary<String, Any> {
        var videoStatsEventData: Dictionary<String, Any> = [:];
        videoStatsEventData["videoPacketsLost"] = videoStats.videoPacketsLost;
        videoStatsEventData["videoBytesReceived"] = videoStats.videoBytesReceived;
        videoStatsEventData["videoPacketsReceived"] = videoStats.videoPacketsReceived;
        return videoStatsEventData;
    }
    
    static func prepareSubscriberAudioNetworkStatsEventData(_ audioStats: OTSubscriberKitAudioNetworkStats) -> Dictionary<String, Any> {
        var audioStatsEventData: Dictionary<String, Any> = [:];
        audioStatsEventData["audioPacketsLost"] = audioStats.audioPacketsLost;
        audioStatsEventData["audioBytesReceived"] = audioStats.audioBytesReceived;
        audioStatsEventData["audioPacketsReceived"] = audioStats.audioPacketsReceived;
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
        return ["\(sessionPreface)streamCreated", "\(sessionPreface)streamDestroyed", "\(sessionPreface)sessionDidConnect", "\(sessionPreface)sessionDidDisconnect", "\(sessionPreface)connectionCreated", "\(sessionPreface)connectionDestroyed", "\(sessionPreface)didFailWithError", "\(publisherPreface)streamCreated", "\(sessionPreface)signal", "\(publisherPreface)streamDestroyed", "\(publisherPreface)didFailWithError", "\(publisherPreface)audioLevelUpdated", "\(subscriberPreface)subscriberDidConnect", "\(subscriberPreface)subscriberDidDisconnect", "\(subscriberPreface)didFailWithError", "\(subscriberPreface)videoNetworkStatsUpdated", "\(subscriberPreface)audioNetworkStatsUpdated", "\(subscriberPreface)audioLevelUpdated", "\(subscriberPreface)subscriberVideoEnabled", "\(subscriberPreface)subscriberVideoDisabled", "\(subscriberPreface)subscriberVideoDisableWarning", "\(subscriberPreface)subscriberVideoDisableWarningLifted", "\(subscriberPreface)subscriberVideoDataReceived", "\(sessionPreface)archiveStartedWithId", "\(sessionPreface)archiveStoppedWithId", "\(sessionPreface)sessionDidBeginReconnecting", "\(sessionPreface)sessionDidReconnect", "\(sessionPreface)streamPropertyChanged", "\(subscriberPreface)subscriberDidReconnect"];
    }
    
    static func convertDateToString(_ creationTime: Date) -> String {
        let dateFormatter: DateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss";
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC");
        return dateFormatter.string(from:creationTime);
    }
    
}
