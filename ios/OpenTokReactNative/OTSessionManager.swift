//
//  OTSessionManager.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/12/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation

@objc(OTSessionManager)
class OTSessionManager: RCTEventEmitter {
  
  var connectCallback: RCTResponseSenderBlock?
  var jsEvents: [String] = [];
  var componentEvents: [String] = [];
  var sessionPreface: String = "session:";
  var publisherPreface: String = "publisher:";
  var subscriberPreface: String = "subscriber:";

  deinit {
    OTRN.sharedState.subscriberStreams.removeAll();
    OTRN.sharedState.session = nil;
    OTRN.sharedState.isPublishing.removeAll();
    OTRN.sharedState.publishers.removeAll();
    OTRN.sharedState.subscribers.removeAll();
  }
    
  override static func requiresMainQueueSetup() -> Bool {
    return true;
  }
    
    @objc override func supportedEvents() -> [String] {
        let allEvents: [String] = ["\(sessionPreface)streamCreated", "\(sessionPreface)streamDestroyed", "\(sessionPreface)sessionDidConnect", "\(sessionPreface)sessionDidDisconnect", "\(sessionPreface)connectionCreated", "\(sessionPreface)connectionDestroyed", "\(sessionPreface)didFailWithError", "\(publisherPreface)streamCreated", "\(sessionPreface)signal", "\(publisherPreface)streamDestroyed", "\(publisherPreface)didFailWithError", "\(publisherPreface)audioLevelUpdated", "\(subscriberPreface)subscriberDidConnect", "\(subscriberPreface)subscriberDidDisconnect", "\(subscriberPreface)didFailWithError", "\(subscriberPreface)videoNetworkStatsUpdated", "\(subscriberPreface)audioNetworkStatsUpdated", "\(subscriberPreface)audioLevelUpdated", "\(subscriberPreface)subscriberVideoEnabled", "\(subscriberPreface)subscriberVideoDisabled", "\(subscriberPreface)subscriberVideoDisableWarning", "\(subscriberPreface)subscriberVideoDisableWarningLifted", "\(subscriberPreface)subscriberVideoDataReceived", "\(sessionPreface)archiveStartedWithId", "\(sessionPreface)archiveStoppedWithId", "\(sessionPreface)sessionDidBeginReconnecting", "\(sessionPreface)sessionDidReconnect", "\(sessionPreface)streamPropertyChanged"];
        return allEvents + jsEvents
    }
  @objc func initSession(_ apiKey: String, sessionId: String) -> Void {
    OTRN.sharedState.session = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self)
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
  
  @objc func initPublisher(_ publisherId: String, properties: Dictionary<String, Any>, callback: @escaping RCTResponseSenderBlock) -> Void {
    DispatchQueue.main.async {
      let publisherProperties = OTPublisherSettings()
      publisherProperties.videoTrack = self.sanitizeBooleanProperty(properties["videoTrack"] as Any);
      publisherProperties.audioTrack = self.sanitizeBooleanProperty(properties["audioTrack"] as Any);
      if let audioBitrate = properties["audioBitrate"] as? Int {
        publisherProperties.audioBitrate = Int32(audioBitrate);
      }
      publisherProperties.cameraFrameRate = self.sanitizeFrameRate(properties["frameRate"] as Any);
      publisherProperties.cameraResolution = self.sanitizeCameraResolution(properties["resolution"] as Any);
      publisherProperties.name = properties["name"] as? String;
      OTRN.sharedState.publishers.updateValue(OTPublisher(delegate: self, settings: publisherProperties)!, forKey: publisherId);
      guard let publisher = OTRN.sharedState.publishers[publisherId] else {
        callback(["Error creating publisher"]);
        return
      }
      if let videoSource = properties["videoSource"] as? String, videoSource == "screen" {
        guard let screenView = RCTPresentedViewController()?.view else {
          callback(["Error setting screenshare"]);
          return
        }
          publisher.videoType = .screen;
          publisher.videoCapture = OTScreenCapturer(withView: (screenView))
      } else if let cameraPosition = properties["cameraPosition"] as? String {
          publisher.cameraPosition = cameraPosition == "front" ? .front : .back;
     }
      publisher.audioFallbackEnabled = self.sanitizeBooleanProperty(properties["audioFallbackEnabled"] as Any);
      publisher.publishAudio = self.sanitizeBooleanProperty(properties["publishAudio"] as Any);
      publisher.publishVideo = self.sanitizeBooleanProperty(properties["publishVideo"] as Any);
      publisher.audioLevelDelegate = self;
      callback([NSNull()]);
    }
  }
  
  @objc func publish(_ publisherId: String, callback: RCTResponseSenderBlock) -> Void {
    var error: OTError?
    guard let publisher = OTRN.sharedState.publishers[publisherId] else {
      callback(["Error getting publisher"]);
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
      OTRN.sharedState.streamObservers.removeValue(forKey: streamId);
      OTRN.sharedState.subscribers[streamId]?.view?.removeFromSuperview();
      OTRN.sharedState.subscribers[streamId]?.delegate = nil;
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
      OTRN.sharedState.session?.delegate = nil;
      OTRN.sharedState.session = nil;
      callback([NSNull()])
    }
  }
  
  @objc func publishAudio(_ publisherId: String, pubAudio: Bool) -> Void {
    guard let publisher = OTRN.sharedState.publishers[publisherId] else { return }
    publisher.publishAudio = pubAudio;
  }
  
  @objc func publishVideo(_ publisherId: String, pubVideo: Bool) -> Void {
    guard let publisher = OTRN.sharedState.publishers[publisherId] else { return }
    publisher.publishVideo = pubVideo;
  }
  
  @objc func subscribeToAudio(_ streamId: String, subAudio: Bool) -> Void {
    guard let subscriber = OTRN.sharedState.subscribers[streamId] else { return }
    subscriber.subscribeToAudio = subAudio;
  }
    
  @objc func subscribeToVideo(_ streamId: String, subVideo: Bool) -> Void {
    guard let subscriber = OTRN.sharedState.subscribers[streamId] else { return }
    subscriber.subscribeToVideo = subVideo;
  }
  
  @objc func changeCameraPosition(_ publisherId: String, cameraPosition: String) -> Void {
    guard let publisher = OTRN.sharedState.publishers[publisherId] else { return }
    publisher.cameraPosition = cameraPosition == "front" ? .front : .back;
  }
  
  @objc func setNativeEvents(_ events: Array<String>) -> Void {
    for event in events {
      if (!self.jsEvents.contains(event)) {
        self.jsEvents.append(event);
      }
    }
  }
  
  @objc func setJSComponentEvents(_ events: Array<String>) -> Void {
    for event in events {
      self.componentEvents.append(event);
    }
  }
  
  @objc func removeJSComponentEvents(_ events: Array<String>) -> Void {
    for event in events {
      if let i = self.componentEvents.index(of: event) {
        self.componentEvents.remove(at: i)
      }
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
  
  @objc func destroyPublisher(_ publisherId: String, callback: @escaping RCTResponseSenderBlock) -> Void {
    DispatchQueue.main.async {
      guard let publisher = OTRN.sharedState.publishers[publisherId] else { callback([NSNull()]); return }
      guard let session = OTRN.sharedState.session else {
        self.resetPublisher(publisherId, publisher: publisher);
        callback([NSNull()]);
        return
      }
      var error: OTError?
      if let isPublishing = OTRN.sharedState.isPublishing[publisherId] {
        if (isPublishing) {
          session.unpublish(publisher, error: &error)
        }
      }
      self.resetPublisher(publisherId, publisher: publisher);
      guard let err = error else { callback([NSNull()]); return }
      callback([err.localizedDescription as Any])
    }
  }
  
  @objc func removeNativeEvents(_ events: Array<String>) -> Void {
    for event in events {
      if let i = self.jsEvents.index(of: event) {
        self.jsEvents.remove(at: i)
      }
    }
  }
  
  @objc func getSessionInfo(_ callback: RCTResponseSenderBlock) -> Void {
    guard let session = OTRN.sharedState.session else { callback([NSNull()]); return }
    var sessionInfo: Dictionary<String, Any> = [:];
    if let connection = session.connection {
      sessionInfo["connection"] = self.prepareJSConnectionEventData(connection);
    }
    sessionInfo["sessionId"] = session.sessionId;
    sessionInfo["connectionStatus"] = session.sessionConnectionStatus.rawValue;
    callback([sessionInfo]);
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
    guard OTRN.sharedState.session != nil else { return streamInfo }
    streamInfo["streamId"] = stream.streamId;
    streamInfo["name"] = stream.name;
    streamInfo["connectionId"] = stream.connection.connectionId;
    streamInfo["hasAudio"] = stream.hasAudio;
    streamInfo["hasVideo"] = stream.hasVideo;
    streamInfo["name"] = stream.name;
    streamInfo["creationTime"] = self.convertDateToString(stream.creationTime);
    streamInfo["height"] = stream.videoDimensions.height;
    streamInfo["width"] = stream.videoDimensions.width;
    return streamInfo;
  }
  
  func prepareJSConnectionEventData(_ connection: OTConnection) -> Dictionary<String, Any> {
    var connectionInfo: Dictionary<String, Any> = [:];
    connectionInfo["connectionId"] = connection.connectionId;
    connectionInfo["creationTime"] = self.convertDateToString(connection.creationTime);
    connectionInfo["data"] = connection.data;
    return connectionInfo;
  }
  
  func prepareJSErrorEventData(_ error: OTError) -> Dictionary<String, Any> {
    var errorInfo: Dictionary<String, Any> = [:];
    errorInfo["code"] = error.code;
    errorInfo["message"] = error.localizedDescription;
    return errorInfo;
  }
  
  func resetPublisher(_ publisherId: String, publisher: OTPublisher) -> Void {
    publisher.view?.removeFromSuperview()
    publisher.delegate = nil;
    OTRN.sharedState.isPublishing[publisherId] = false;
  }
  
  func getPublisherId(_ publisher: OTPublisher) -> String {
    let publisherIds = OTRN.sharedState.publishers.filter {$0.value == publisher}
    guard let publisherId = publisherIds.first else { return ""; }
    return publisherId.key;
  }
    
  func convertDateToString(_ creationTime: Date) -> String {
    let dateFormatter: DateFormatter = DateFormatter();
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss";
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC");
    return dateFormatter.string(from:creationTime);
  }
  
  func emitEvent(_ event: String, data: Any) -> Void {
    if (self.jsEvents.contains(event) || self.componentEvents.contains(event)) {
      self.sendEvent(withName: event, body: data);
    }
  }
    
  func prepareStreamPropertyChangedEventData(_ changedProperty: String, oldValue: Any, newValue: Any, stream: Dictionary<String, Any>) -> Dictionary<String, Any> {
    var streamPropertyEventData: Dictionary<String, Any> = [:];
    streamPropertyEventData["oldValue"] = oldValue;
    streamPropertyEventData["newValue"] = newValue;
    streamPropertyEventData["stream"] = stream;
    streamPropertyEventData["changedProperty"] = changedProperty;
    return streamPropertyEventData
  }

  func convertOTSubscriberVideoEventReasonToString(_ reason: OTSubscriberVideoEventReason) -> String {
    switch reason {
    case OTSubscriberVideoEventReason.publisherPropertyChanged:
        return "PublisherPropertyChanged"
    case OTSubscriberVideoEventReason.subscriberPropertyChanged:
        return "SubscriberPropertyChanged"
    case OTSubscriberVideoEventReason.qualityChanged:
        return "QualityChanged"
    }
  }
  
  func checkAndEmitStreamPropertyChangeEvent(_ streamId: String, changedProperty: String, oldValue: Any, newValue: Any) {
    guard let stream = OTRN.sharedState.subscriberStreams[streamId] else { return }
    let streamInfo: Dictionary<String, Any> = prepareJSEventData(stream);
    let eventData: Dictionary<String, Any> = prepareStreamPropertyChangedEventData(changedProperty, oldValue: oldValue, newValue: newValue, stream: streamInfo);
    self.emitEvent("\(sessionPreface)streamPropertyChanged", data: eventData)
  }
}

extension OTSessionManager: OTSessionDelegate {
  func sessionDidConnect(_ session: OTSession) {
    guard let callback = connectCallback else { return }
    callback([NSNull()])
    print("OTRN: Session connected")
    self.emitEvent("\(sessionPreface)sessionDidConnect", data: [NSNull()]);
  }
  
  func sessionDidDisconnect(_ session: OTSession) {
    self.emitEvent("\(sessionPreface)sessionDidDisconnect", data: [NSNull()]);
    print("OTRN: Session disconnected")
  }
  
  func session(_ session: OTSession, connectionCreated connection: OTConnection) {
    let connectionInfo = prepareJSConnectionEventData(connection);
    self.emitEvent("\(sessionPreface)connectionCreated", data: connectionInfo)
    print("OTRN Session: A connection was created \(connection.connectionId)")
  }
  func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
    let connectionInfo = prepareJSConnectionEventData(connection);
    self.emitEvent("\(sessionPreface)connectionDestroyed", data: connectionInfo)
    print("OTRN Session: A connection was destroyed")
  }
  
  func session(_ session: OTSession, archiveStartedWithId archiveId: String, name: String?) {
    var archiveInfo: Dictionary<String, String> = [:];
    archiveInfo["archiveId"] = archiveId;
    archiveInfo["name"] = name;
    self.emitEvent("\(sessionPreface)archiveStartedWithId", data: archiveInfo)
    print ("OTRN Session: Archive started with \(archiveId)")
  }
  
  func session(_ session: OTSession, archiveStoppedWithId archiveId: String) {
    self.emitEvent("\(sessionPreface)archiveStoppedWithId", data: archiveId);
    print("OTRN Session: Archive stopped with \(archiveId)")
  }
  
  func sessionDidBeginReconnecting(_ session: OTSession) {
    self.emitEvent("\(sessionPreface)sessionDidBeginReconnecting", data: [NSNull()])
    print("OTRN Session: Session did begin reconnecting")
  }
  
  func sessionDidReconnect(_ session: OTSession) {
    self.emitEvent("\(sessionPreface)sessionDidReconnect", data: [NSNull()])
    print("OTRN Session: Session reconnected")
  }
  
  func session(_ session: OTSession, streamCreated stream: OTStream) {
    OTRN.sharedState.subscriberStreams.updateValue(stream, forKey: stream.streamId)
    let streamInfo: Dictionary<String, Any> = prepareJSEventData(stream);
    self.emitEvent("\(sessionPreface)streamCreated", data: streamInfo)
    let hasVideoObservation: NSKeyValueObservation = stream.observe(\.hasVideo, options: [.old, .new]) { object, change in
        guard let oldValue = change.oldValue else { return }
        guard let newValue = change.newValue else { return }
        self.checkAndEmitStreamPropertyChangeEvent(stream.streamId, changedProperty: "hasVideo", oldValue: oldValue, newValue: newValue)
    }
    let hasAudioObservation: NSKeyValueObservation = stream.observe(\.hasAudio, options: [.old, .new]) { object, change in
        guard let oldValue = change.oldValue else { return }
        guard let newValue = change.newValue else { return }
        self.checkAndEmitStreamPropertyChangeEvent(stream.streamId, changedProperty: "hasAudio", oldValue: oldValue, newValue: newValue)
    }
    let videoDimensionsObservation: NSKeyValueObservation = stream.observe(\.videoDimensions, options: [.old, .new]) { object, change in
        guard let oldValue = change.oldValue else { return }
        guard let newValue = change.newValue else { return }
        self.checkAndEmitStreamPropertyChangeEvent(stream.streamId, changedProperty: "videoDimensions", oldValue: oldValue, newValue: newValue)
    }
    let videoTypeObservation: NSKeyValueObservation = stream.observe(\.videoType, options: [.old, .new]) { object, change in
        guard let oldValue = change.oldValue else { return }
        guard let newValue = change.newValue else { return }
        self.checkAndEmitStreamPropertyChangeEvent(stream.streamId, changedProperty: "videoType", oldValue: oldValue, newValue: newValue)
    }
    OTRN.sharedState.streamObservers.updateValue([hasAudioObservation, hasVideoObservation, videoDimensionsObservation, videoTypeObservation], forKey: stream.streamId)
  }
  
  func session(_ session: OTSession, streamDestroyed stream: OTStream) {
    let streamInfo: Dictionary<String, Any> = prepareJSEventData(stream);
    self.emitEvent("\(sessionPreface)streamDestroyed", data: streamInfo)
    print("OTRN: Session streamDestroyed: \(stream.streamId)")
  }
  
  func session(_ session: OTSession, didFailWithError error: OTError) {
    let errorInfo: Dictionary<String, Any> = prepareJSErrorEventData(error);
    self.emitEvent("\(sessionPreface)didFailWithError", data: errorInfo)
    print("OTRN: Session Failed to connect: \(error.localizedDescription)")
  }
  
  func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
    var signalData: Dictionary<String, Any> = [:];
    signalData["type"] = type;
    signalData["data"] = string;
    signalData["connectionId"] = connection?.connectionId;
    self.emitEvent("\(sessionPreface)signal", data: signalData)
    print("OTRN: Session signal received")
  }
}

extension OTSessionManager: OTPublisherDelegate {
  func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
    let publisherId = self.getPublisherId(publisher as! OTPublisher);
    if (publisherId.count > 0) {
      OTRN.sharedState.isPublishing[publisherId] = true;
      let streamInfo: Dictionary<String, Any> = prepareJSEventData(stream);
      self.emitEvent("\(publisherId):\(publisherPreface)streamCreated", data: streamInfo);
    }
    print("OTRN: Publisher Stream created")
  }
  
  func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
    let publisherId = self.getPublisherId(publisher as! OTPublisher);
    if (publisherId.count > 0) {
      OTRN.sharedState.isPublishing[publisherId] = false;
      let streamInfo: Dictionary<String, Any> = prepareJSEventData(stream);
      self.emitEvent("\(publisherId):\(publisherPreface)streamDestroyed", data: streamInfo);
    }
    print("OTRN: Publisher Stream destroyed")
  }
  
  func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
    let publisherId = self.getPublisherId(publisher as! OTPublisher);
    if (publisherId.count > 0) {
      let errorInfo: Dictionary<String, Any> = prepareJSErrorEventData(error);
      self.emitEvent("\(publisherId):\(publisherPreface)didFailWithError", data: errorInfo)
    }
    print("OTRN: Publisher failed: \(error.localizedDescription)")
  }
}

extension OTSessionManager: OTPublisherKitAudioLevelDelegate {
  func publisher(_ publisher: OTPublisherKit, audioLevelUpdated audioLevel: Float) {
    let publisherId = self.getPublisherId(publisher as! OTPublisher);
    if (publisherId.count > 0) {
      self.emitEvent("\(publisherId):\(publisherPreface)audioLevelUpdated", data: audioLevel)
    }
  }
}

extension OTSessionManager: OTSubscriberDelegate {
  func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
    self.emitEvent("\(subscriberPreface)subscriberDidConnect", data: [NSNull()]);
    print("OTRN: Subscriber connected")
  }
  
  func subscriberDidDisconnect(fromStream subscriberKit: OTSubscriberKit) {
    self.emitEvent("\(subscriberPreface)subscriberDidDisconnect", data: [NSNull()]);
    print("OTRN: Subscriber disconnected")
  }
  
  func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
    let errorInfo: Dictionary<String, Any> = prepareJSErrorEventData(error);
    self.emitEvent("\(subscriberPreface)didFailWithError", data: errorInfo)
    print("OTRN: Subscriber failed: \(error.localizedDescription)")
  }
  
}

extension OTSessionManager: OTSubscriberKitNetworkStatsDelegate {
  func subscriber(_ subscriber: OTSubscriberKit, videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats) {
    var videoStats: Dictionary<String, Any> = [:];
    videoStats["videoPacketsLost"] = stats.videoPacketsLost;
    videoStats["videoBytesReceived"] = stats.videoBytesReceived;
    videoStats["videoPacketsReceived"] = stats.videoPacketsReceived;
    self.emitEvent("\(subscriberPreface)videoNetworkStatsUpdated", data: videoStats);
  }
  
  func subscriber(_ subscriber: OTSubscriberKit, audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats) {
    var audioStats: Dictionary<String, Any> = [:];
    audioStats["audioPacketsLost"] = stats.audioPacketsLost;
    audioStats["audioBytesReceived"] = stats.audioBytesReceived;
    audioStats["audioPacketsReceived"] = stats.audioPacketsReceived;
    self.emitEvent("\(subscriberPreface)audioNetworkStatsUpdated", data: audioStats);
  }
  
  func subscriberVideoEnabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
    self.emitEvent("\(subscriberPreface)subscriberVideoEnabled", data: reason);
  }
  
  func subscriberVideoDisabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
    self.emitEvent("\(subscriberPreface)subscriberVideoDisabled", data: reason);
  }
  
  func subscriberVideoDisableWarning(_ subscriber: OTSubscriberKit) {
    self.emitEvent("\(subscriberPreface)subscriberVideoDisableWarning", data: [NSNull()]);
  }
  
  func subscriberVideoDisableWarningLifted(_ subscriber: OTSubscriberKit) {
    self.emitEvent("\(subscriberPreface)subscriberVideoDisableWarningLifted", data: [NSNull()]);
  }
  
  func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    self.emitEvent("\(subscriberPreface)subscriberVideoDataReceived", data: [NSNull()]);
  }
}

extension OTSessionManager: OTSubscriberKitAudioLevelDelegate {
  func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
    self.emitEvent("\(subscriberPreface)audioLevelUpdated", data: audioLevel);
  }
}
