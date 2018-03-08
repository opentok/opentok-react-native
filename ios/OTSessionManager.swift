//
//  OTSessionManager.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/12/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation
import OpenTok

@objc(OTSessionManager)
class OTSessionManager: RCTEventEmitter {
  
  var connectCallback: RCTResponseSenderBlock?
  var jsEvents: [String] = [];
  var sessionPreface: String = "session:";
  var publisherPreface: String = "publisher:";
  var subscriberPreface: String = "subscriber:";
  @objc override func supportedEvents() -> [String] {
    let allEvents: [String] = ["\(sessionPreface)streamCreated", "\(sessionPreface)streamDestroyed", "\(sessionPreface)sessionDidConnect", "\(sessionPreface)sessionDidDisconnect", "\(sessionPreface)connectionCreated", "\(sessionPreface)connectionDestroyed", "\(sessionPreface)didFailWithError", "\(publisherPreface)streamCreated", "\(sessionPreface)signal", "\(publisherPreface)streamDestroyed", "\(publisherPreface)didFailWithError", "\(publisherPreface)audioLevelUpdated", "\(subscriberPreface)subscriberDidConnect", "\(subscriberPreface)subscriberDidDisconnect", "\(subscriberPreface)didFailWithError", "\(subscriberPreface)videoNetworkStatsUpdated", "\(subscriberPreface)audioNetworkStatsUpdated", "\(subscriberPreface)audioLevelUpdated", "\(subscriberPreface)subscriberVideoEnabled", "\(subscriberPreface)subscriberVideoDisabled", "\(subscriberPreface)subscriberVideoDisableWarning", "\(subscriberPreface)subscriberVideoDisableWarningLifted", "\(subscriberPreface)subscriberVideoDataReceived", "\(sessionPreface)archiveStartedWithId", "\(sessionPreface)archiveStoppedWithId", "\(sessionPreface)sessionDidBeginReconnecting", "\(sessionPreface)sessionDidReconnect"];
    return allEvents
  }
  
  @objc func initSession(_ apiKey: String, sessionId: String) -> Void {
    OTRN.sharedState.session = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self)!
  }
  
  @objc func connect(_ token: String, callback: @escaping RCTResponseSenderBlock) -> Void {
    var error: OTError?
    OTRN.sharedState.session?.connect(withToken: token, error: &error)
    if let err = error {
      callback([err.localizedDescription as Any])
    } else {
      connectCallback = callback
    }
  }

  @objc func initPublisher(_ properties: Dictionary<String, Any>, callback: @escaping RCTResponseSenderBlock) -> Void {
    DispatchQueue.main.async {
      let publisherProperties = OTPublisherSettings()
      publisherProperties.videoTrack = self.sanitizeBooleanProperty(properties["videoTrack"] as Any);
      publisherProperties.audioTrack = self.sanitizeBooleanProperty(properties["audioTrack"] as Any);
      if let cameraPosition = properties["cameraPosition"] as? String {
        OTRN.sharedState.publisher?.cameraPosition = cameraPosition == "front" ? .front : .back;
      }
      if let audioBitrate = properties["audioBitrate"] as? Int {
        publisherProperties.audioBitrate = Int32(audioBitrate);
      }
      publisherProperties.cameraFrameRate = self.sanitizeFrameRate(properties["frameRate"] as Any);
      publisherProperties.cameraResolution = self.sanitizeCameraResolution(properties["resolution"] as Any);
      publisherProperties.name = properties["name"] as? String;
      OTRN.sharedState.publisher = OTPublisher(delegate: self, settings: publisherProperties)!
      OTRN.sharedState.publisher?.audioFallbackEnabled = self.sanitizeBooleanProperty(properties["audioFallbackEnabled"] as Any);
      OTRN.sharedState.publisher?.publishAudio = self.sanitizeBooleanProperty(properties["publishAudio"] as Any);
      OTRN.sharedState.publisher?.publishVideo = self.sanitizeBooleanProperty(properties["publishVideo"] as Any);
      OTRN.sharedState.publisher?.audioLevelDelegate = self;
      callback([NSNull()])
    }
  }
  
  @objc func publish(_ callback: RCTResponseSenderBlock) -> Void {
    var error: OTError?
    guard let publisher = OTRN.sharedState.publisher else {
      callback(["Error setting publisher"])
      return
    }
    OTRN.sharedState.session?.publish(publisher, error: &error)
    if let err = error {
      callback([err.localizedDescription as Any])
    } else {
      callback([NSNull()])
    }
  }
  
  @objc func subscribeToStream(_ streamId: String, properties: Dictionary<String, Any>, callback: @escaping RCTResponseSenderBlock) -> Void {
    var error: OTError?
    DispatchQueue.main.async {
      OTRN.sharedState.subscribers.updateValue(OTSubscriber(stream: OTRN.sharedState.subscriberStreams[streamId]!, delegate: self)!, forKey: streamId)
      OTRN.sharedState.subscribers[streamId]?.networkStatsDelegate = self;
      OTRN.sharedState.subscribers[streamId]?.audioLevelDelegate = self;
      OTRN.sharedState.session?.subscribe(OTRN.sharedState.subscribers[streamId]!, error: &error)
      OTRN.sharedState.subscribers[streamId]?.subscribeToAudio = self.sanitizeBooleanProperty(properties["subscribeToAudio"] as Any);
      OTRN.sharedState.subscribers[streamId]?.subscribeToVideo = self.sanitizeBooleanProperty(properties["subscribeToVideo"] as Any);
      if let err = error {
        callback([err.localizedDescription as Any])
      } else {
        callback([NSNull(), streamId])
      }
    }
  }
  
  @objc func removeSubscriber(_ streamId: String, callback: @escaping RCTResponseSenderBlock) -> Void {
    DispatchQueue.main.async {
      OTRN.sharedState.subscribers[streamId]?.view?.removeFromSuperview();
      OTRN.sharedState.subscribers[streamId] = nil;
      OTRN.sharedState.subscriberStreams[streamId] = nil;
      callback([NSNull()])
    }

  }
  
  @objc func disconnectSession(_ callback: RCTResponseSenderBlock) -> Void {
    var error: OTError?
    OTRN.sharedState.session?.disconnect(&error)
    if let err = error {
      callback([err.localizedDescription as Any])
    } else {
      callback([NSNull()])
    }
  }
  
  @objc func publishAudio(_ pubAudio: Bool) -> Void {
    OTRN.sharedState.publisher?.publishAudio = pubAudio;
  }
  
  @objc func publishVideo(_ pubVideo: Bool) -> Void {
    OTRN.sharedState.publisher?.publishVideo = pubVideo;
  }
  

  @objc func setNativeEvents(_ events: Array<String>) -> Void {
    for event in events {
      self.jsEvents.append(event);
    }
  }
  
  @objc func sendSignal(_ signal: Dictionary<String, String>, callback: RCTResponseSenderBlock ) -> Void {
    let connection: OTConnection? = nil
    var error: OTError?
    OTRN.sharedState.session?.signal(withType: signal["type"], string: signal["data"], connection: connection, error: &error)
    if let err = error {
      callback([err.localizedDescription as Any])
    } else {
      callback([NSNull()])
    }
  }
  
  @objc func destroyPublisher(_ callback: @escaping RCTResponseSenderBlock) -> Void {
    DispatchQueue.main.async {
      guard let publisher = OTRN.sharedState.publisher else { return }
      var error: OTError?
      OTRN.sharedState.session?.unpublish(publisher, error: &error)
      if let err = error {
        callback([err.localizedDescription as Any])
      } else {
        publisher.view?.removeFromSuperview()
        callback([NSNull()])
      }
    }
  }
  
  @objc func removeNativeEvents(_ events: Array<String>) -> Void {
    for event in events {
      if let i = self.jsEvents.index(of: event) {
        self.jsEvents.remove(at: i)
      }
    }
  }
  
  func sanitizeBooleanProperty(_ property: Any) -> Bool {
    guard let prop = property as? Bool else { return true; }
    return prop;
  }
  
  func sanitizeFrameRate(_ frameRate: Any) -> OTCameraCaptureFrameRate {
    guard let cameraFrameRate = frameRate as? Int else { return OTCameraCaptureFrameRate(rawValue: 30)!; }
    return OTCameraCaptureFrameRate(rawValue: cameraFrameRate)!;
  }
  
  func sanitizeCameraResolution(_ resolution: Any) -> OTCameraCaptureResolution {
    guard let cameraResolution = resolution as? String else { return .medium };
    switch cameraResolution {
      case "HIGH":
        return .high;
      case "LOW":
        return .low;
      default:
        return .medium;
    }
  }
  
  func prepareJSEventData(_ stream: OTStream) -> Dictionary<String, Any> {
    var streamInfo: Dictionary<String, Any> = [:];
    streamInfo["streamId"] = stream.streamId;
    streamInfo["name"] = stream.name;
    streamInfo["connectionId"] = stream.connection.connectionId;
    streamInfo["hasAudio"] = stream.hasAudio;
    streamInfo["hasVideo"] = stream.hasVideo;
    streamInfo["name"] = stream.name;
    streamInfo["creationTime"] = stream.creationTime;
    streamInfo["height"] = stream.videoDimensions.height;
    streamInfo["width"] = stream.videoDimensions.width;
    return streamInfo;
  }
  
  func prepareJSConnectionEventData(_ connection: OTConnection) -> Dictionary<String, Any> {
    var connectionInfo: Dictionary<String, Any> = [:];
    connectionInfo["connectionId"] = connection.connectionId;
    connectionInfo["creationTime"] = connection.creationTime;
    connectionInfo["data"] = connection.data;
    return connectionInfo;
  }
  
  func prepareJSErrorEventData(_ error: OTError) -> Dictionary<String, Any> {
    var errorInfo: Dictionary<String, Any> = [:];
    errorInfo["code"] = error.code;
    errorInfo["message"] = error.localizedDescription;
    return errorInfo;
  }
  
}

extension OTSessionManager: OTSessionDelegate {
  func sessionDidConnect(_ session: OTSession) {
    guard let callback = connectCallback else {
      return
    }
    callback([NSNull()])
    print("OTRN: Session connected")
    if (self.jsEvents.contains("\(sessionPreface)sessionDidConnect")) {
      self.sendEvent(withName: "\(sessionPreface)sessionDidConnect", body: [NSNull()]);
    }
  }
  
  func sessionDidDisconnect(_ session: OTSession) {
    if (self.jsEvents.contains("\(sessionPreface)sessionDidDisconnect")) {
      self.sendEvent(withName: "\(sessionPreface)sessionDidDisconnect", body: [NSNull()]);
    }
    print("OTRN: Session disconnected")
  }
  
  func session(_ session: OTSession, connectionCreated connection: OTConnection) {
    if (self.jsEvents.contains("\(sessionPreface)connectionCreated")) {
      let connectionInfo = prepareJSConnectionEventData(connection);
      self.sendEvent(withName: "\(sessionPreface)connectionCreated", body: connectionInfo)
    }
    print("OTRN Session: A connection was created \(connection.connectionId)")
  }
  func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
    if (self.jsEvents.contains("\(sessionPreface)connectionDestroyed")) {
      let connectionInfo = prepareJSConnectionEventData(connection);
      self.sendEvent(withName: "\(sessionPreface)connectionDestroyed", body: connectionInfo)
    }
    print("OTRN Session: A connection was destroyed")
  }
  
  func session(_ session: OTSession, archiveStartedWithId archiveId: String, name: String?) {
    if (self.jsEvents.contains("\(sessionPreface)archiveStartedWithId")) {
      var archiveInfo: Dictionary<String, String> = [:];
      archiveInfo["archiveId"] = archiveId;
      archiveInfo["name"] = name;
      self.sendEvent(withName: "\(sessionPreface)archiveStartedWithId", body: archiveInfo)
    }
    print ("OTRN Session: Archive started with \(archiveId)")
  }
  
  func session(_ session: OTSession, archiveStoppedWithId archiveId: String) {
    if (self.jsEvents.contains("\(sessionPreface)archiveStoppedWithId")) {
      self.sendEvent(withName: "\(sessionPreface)archiveStoppedWithId", body: archiveId)
    }
    print("OTRN Session: Archive stopped with \(archiveId)")
  }
  
  func sessionDidBeginReconnecting(_ session: OTSession) {
    if (self.jsEvents.contains("\(sessionPreface)sessionDidBeginReconnecting")) {
      self.sendEvent(withName: "\(sessionPreface)sessionDidBeginReconnecting", body: [NSNull()])
    }
    print("OTRN Session: Session did begin reconnecting")
  }
  
  func sessionDidReconnect(_ session: OTSession) {
    if (self.jsEvents.contains("\(sessionPreface)sessionDidReconnect")) {
      self.sendEvent(withName: "\(sessionPreface)sessionDidReconnect", body: [NSNull()])
    }
    print("OTRN Session: Session reconnected")
  }
  
  func session(_ session: OTSession, streamCreated stream: OTStream) {
    if (self.jsEvents.contains("\(sessionPreface)streamCreated")) {
      OTRN.sharedState.subscriberStreams.updateValue(stream, forKey: stream.streamId)
      let streamInfo: Dictionary<String, Any> = prepareJSEventData(stream);
      self.sendEvent(withName: "\(sessionPreface)streamCreated", body: streamInfo)
    }
    print("OTRN: Session streamCreated with streamId: \(stream.streamId)")
  }
  
  func session(_ session: OTSession, streamDestroyed stream: OTStream) {
    if (self.jsEvents.contains("\(sessionPreface)streamDestroyed")) {
      let streamInfo: Dictionary<String, Any> = prepareJSEventData(stream);
      self.sendEvent(withName: "\(sessionPreface)streamDestroyed", body: streamInfo)
    }
    print("OTRN: Session streamDestroyed: \(stream.streamId)")
  }
  
  func session(_ session: OTSession, didFailWithError error: OTError) {
    if (self.jsEvents.contains("\(sessionPreface)didFailWithError")) {
      let errorInfo: Dictionary<String, Any> = prepareJSErrorEventData(error);
      self.sendEvent(withName: "\(sessionPreface)didFailWithError", body: errorInfo)
    }
    print("OTRN: Session Failed to connect: \(error.localizedDescription)")
  }
  
  func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
    if (self.jsEvents.contains("\(sessionPreface)signal")) {
      var signalData: Dictionary<String, Any> = [:];
      signalData["type"] = type;
      signalData["data"] = string;
      signalData["connectionId"] = connection?.connectionId;
      self.sendEvent(withName: "\(sessionPreface)signal", body: signalData)
    }
    print("OTRN: Session signal received")
  }
}

extension OTSessionManager: OTPublisherDelegate {
  func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
    if (self.jsEvents.contains("\(publisherPreface)streamCreated")) {
      let streamInfo: Dictionary<String, Any> = prepareJSEventData(stream);
      self.sendEvent(withName: "\(publisherPreface)streamCreated", body: streamInfo)
    }
    print("OTRN: Publisher Stream created")
  }
  
  func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
    if (self.jsEvents.contains("\(publisherPreface)streamDestroyed")) {
      let streamInfo: Dictionary<String, Any> = prepareJSEventData(stream);
      self.sendEvent(withName: "\(publisherPreface)streamDestroyed", body: streamInfo)
    }
    print("OTRN: Publisher Stream destroyed")
  }
  
  func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
    if (self.jsEvents.contains("\(publisherPreface)didFailWithError")) {
      let errorInfo: Dictionary<String, Any> = prepareJSErrorEventData(error);
      self.sendEvent(withName: "\(publisherPreface)didFailWithError", body: errorInfo)
    }
    print("OTRN: Publisher failed: \(error.localizedDescription)")
  }
}

extension OTSessionManager: OTPublisherKitAudioLevelDelegate {
  func publisher(_ publisher: OTPublisherKit, audioLevelUpdated audioLevel: Float) {
    if (self.jsEvents.contains("\(publisherPreface)audioLevelUpdated")) {
      self.sendEvent(withName: "\(publisherPreface)audioLevelUpdated", body: audioLevel)
    }
  }
}

extension OTSessionManager: OTSubscriberDelegate {
  func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
    if (self.jsEvents.contains("\(subscriberPreface)subscriberDidConnect")) {
      self.sendEvent(withName: "\(subscriberPreface)subscriberDidConnect", body: [NSNull()]);
    }
    print("OTRN: Subscriber connected")
  }
  
  func subscriberDidDisconnect(fromStream subscriberKit: OTSubscriberKit) {
    if (self.jsEvents.contains("\(subscriberPreface)subscriberDidDisconnect")) {
      self.sendEvent(withName: "\(subscriberPreface)subscriberDidDisconnect", body: [NSNull()]);
    }
    print("OTRN: Subscriber disconnected")
  }
  
  func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
    if (self.jsEvents.contains("\(subscriberPreface)didFailWithError")) {
      let errorInfo: Dictionary<String, Any> = prepareJSErrorEventData(error);
      self.sendEvent(withName: "\(subscriberPreface)didFailWithError", body: errorInfo);
    }
    print("OTRN: Subscriber failed: \(error.localizedDescription)")
  }
  
}

extension OTSessionManager: OTSubscriberKitNetworkStatsDelegate {
  func subscriber(_ subscriber: OTSubscriberKit, videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats) {
    if (self.jsEvents.contains("\(subscriberPreface)videoNetworkStatsUpdated")) {
      var videoStats: Dictionary<String, Any> = [:];
      videoStats["videoPacketsLost"] = stats.videoPacketsLost;
      videoStats["videoBytesReceived"] = stats.videoBytesReceived;
      videoStats["videoPacketsReceived"] = stats.videoPacketsReceived;
      self.sendEvent(withName: "\(subscriberPreface)videoNetworkStatsUpdated", body: [NSNull()])
    }
  }
  
  func subscriber(_ subscriber: OTSubscriberKit, audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats) {
    if (self.jsEvents.contains("\(subscriberPreface)audioNetworkStatsUpdated")) {
      var audioStats: Dictionary<String, Any> = [:];
      audioStats["audioPacketsLost"] = stats.audioPacketsLost;
      audioStats["audioBytesReceived"] = stats.audioBytesReceived;
      audioStats["audioPacketsReceived"] = stats.audioPacketsReceived;
      self.sendEvent(withName: "\(subscriberPreface)audioNetworkStatsUpdated", body: audioStats)
    }
  }
  
  func subscriberVideoEnabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
    if (self.jsEvents.contains("\(subscriberPreface)subscriberVideoEnabled")) {
      self.sendEvent(withName: "\(subscriberPreface)subscriberVideoEnabled", body: reason)
    }
  }
  
  func subscriberVideoDisabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
    if (self.jsEvents.contains("\(subscriberPreface)subscriberVideoEnabled")) {
      self.sendEvent(withName: "\(subscriberPreface)subscriberVideoEnabled", body: reason)
    }
  }
  
  func subscriberVideoDisableWarning(_ subscriber: OTSubscriberKit) {
    if (self.jsEvents.contains("\(subscriberPreface)subscriberVideoDisableWarning")) {
      self.sendEvent(withName: "\(subscriberPreface)subscriberVideoDisableWarning", body: [NSNull()])
    }
  }
  
  func subscriberVideoDisableWarningLifted(_ subscriber: OTSubscriberKit) {
    if (self.jsEvents.contains("\(subscriberPreface)subscriberVideoDisableWarningLifted")) {
      self.sendEvent(withName: "\(subscriberPreface)subscriberVideoDisableWarningLifted", body: [NSNull()])
    }
  }
  
  func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    if (self.jsEvents.contains("\(subscriberPreface)subscriberVideoDataReceived")) {
      self.sendEvent(withName: "\(subscriberPreface)subscriberVideoDataReceived", body: [NSNull()])
    }
  }
}

extension OTSessionManager: OTSubscriberKitAudioLevelDelegate {
  func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
    if (self.jsEvents.contains("\(subscriberPreface)audioLevelUpdated")) {
      self.sendEvent(withName: "\(subscriberPreface)audioLevelUpdated" , body: audioLevel)
    }
  }
}
