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
    var disconnectCallback: RCTResponseSenderBlock?
    var jsEvents: [String] = [];
    var componentEvents: [String] = [];
    var logLevel: Bool = false;
    
    deinit {
        OTRN.sharedState.subscriberStreams.removeAll();
        OTRN.sharedState.session = nil;
        OTRN.sharedState.isPublishing.removeAll();
        OTRN.sharedState.publishers.removeAll();
        OTRN.sharedState.subscribers.removeAll();
        OTRN.sharedState.publisherDestroyedCallbacks.removeAll();
        OTRN.sharedState.connections.removeAll();
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true;
    }
    
    @objc override func supportedEvents() -> [String] {
        let allEvents = EventUtils.getSupportedEvents();
        return allEvents + jsEvents
    }
    
    @objc func initSession(_ apiKey: String, sessionId: String, sessionOptions: Dictionary<String, Any>) -> Void {
        let settings = OTSessionSettings()
        settings.connectionEventsSuppressed = Utils.sanitizeBooleanProperty(sessionOptions["connectionEventsSuppressed"] as Any);
        OTRN.sharedState.session = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self, settings: settings)
    }
    
    @objc func connect(_ token: String, callback: @escaping RCTResponseSenderBlock) -> Void {
        var error: OTError?
        OTRN.sharedState.session?.connect(withToken: token, error: &error)
        if let err = error {
            self.dispatchErrorViaCallback(callback, error: err)
        } else {
            connectCallback = callback
        }
    }
    
    @objc func initPublisher(_ publisherId: String, properties: Dictionary<String, Any>, callback: @escaping RCTResponseSenderBlock) -> Void {
        DispatchQueue.main.async {
            let publisherProperties = OTPublisherSettings()
            publisherProperties.videoTrack = Utils.sanitizeBooleanProperty(properties["videoTrack"] as Any);
            publisherProperties.audioTrack = Utils.sanitizeBooleanProperty(properties["audioTrack"] as Any);
            if let audioBitrate = properties["audioBitrate"] as? Int {
                publisherProperties.audioBitrate = Int32(audioBitrate);
            }
            publisherProperties.cameraFrameRate = Utils.sanitizeFrameRate(properties["frameRate"] as Any);
            publisherProperties.cameraResolution = Utils.sanitizeCameraResolution(properties["resolution"] as Any);
            publisherProperties.name = properties["name"] as? String;
            OTRN.sharedState.publishers.updateValue(OTPublisher(delegate: self, settings: publisherProperties)!, forKey: publisherId);
            guard let publisher = OTRN.sharedState.publishers[publisherId] else {
                let errorInfo = EventUtils.createErrorMessage("There was an error creating the native publisher instance")
                callback([errorInfo]);
                return
            }
            if let videoSource = properties["videoSource"] as? String, videoSource == "screen" {
                guard let screenView = RCTPresentedViewController()?.view else {
                    let errorInfo = EventUtils.createErrorMessage("There was an error setting the videoSource as screen")
                    callback([errorInfo]);
                    return
                }
                publisher.videoType = .screen;
                publisher.videoCapture = OTScreenCapturer(withView: (screenView))
            } else if let cameraPosition = properties["cameraPosition"] as? String {
                publisher.cameraPosition = cameraPosition == "front" ? .front : .back;
            }
            publisher.audioFallbackEnabled = Utils.sanitizeBooleanProperty(properties["audioFallbackEnabled"] as Any);
            publisher.publishAudio = Utils.sanitizeBooleanProperty(properties["publishAudio"] as Any);
            publisher.publishVideo = Utils.sanitizeBooleanProperty(properties["publishVideo"] as Any);
            publisher.audioLevelDelegate = self;
            callback([NSNull()]);
        }
    }
    
    @objc func publish(_ publisherId: String, callback: RCTResponseSenderBlock) -> Void {
        var error: OTError?
        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            let errorInfo = EventUtils.createErrorMessage("Error publishing. Could not find native publisher instance")
            callback([errorInfo]);
            return
        }
        OTRN.sharedState.session?.publish(publisher, error: &error)
        if let err = error {
            dispatchErrorViaCallback(callback, error: err)
        } else {
            callback([NSNull()])
        }
    }
    
    @objc func subscribeToStream(_ streamId: String, properties: Dictionary<String, Any>, callback: @escaping RCTResponseSenderBlock) -> Void {
        var error: OTError?
        DispatchQueue.main.async {
            guard let stream = OTRN.sharedState.subscriberStreams[streamId] else {
                let errorInfo = EventUtils.createErrorMessage("Error subscribing. Could not find native stream for subscriber.")
                callback([errorInfo]);
                return
            }
            guard let subscriber = OTSubscriber(stream: stream, delegate: self) else {
                let errorInfo = EventUtils.createErrorMessage("Error subscribing. Could not create subscriber.")
                callback([errorInfo]);
                return
            }
            OTRN.sharedState.subscribers.updateValue(subscriber, forKey: streamId)
            subscriber.networkStatsDelegate = self;
            subscriber.audioLevelDelegate = self;
            OTRN.sharedState.session?.subscribe(subscriber, error: &error)
            subscriber.subscribeToAudio = Utils.sanitizeBooleanProperty(properties["subscribeToAudio"] as Any);
            subscriber.subscribeToVideo = Utils.sanitizeBooleanProperty(properties["subscribeToVideo"] as Any);
            if let err = error {
                self.dispatchErrorViaCallback(callback, error: err)
            } else {
                callback([NSNull(), streamId])
            }
        }
    }
    
    @objc func removeSubscriber(_ streamId: String, callback: @escaping RCTResponseSenderBlock) -> Void {
        DispatchQueue.main.async {
            OTRN.sharedState.streamObservers.removeValue(forKey: streamId);
            guard let subscriber = OTRN.sharedState.subscribers[streamId] else {
                self.removeStream(streamId)
                callback([NSNull()])
                return
            }
            subscriber.view?.removeFromSuperview();
            subscriber.delegate = nil;
            self.removeStream(streamId)
            callback([NSNull()])
        }
        
    }
    
    @objc func disconnectSession(_ callback: @escaping RCTResponseSenderBlock) -> Void {
        var error: OTError?
        OTRN.sharedState.session?.disconnect(&error)
        if let err = error {
            dispatchErrorViaCallback(callback, error: err)
        } else {
            disconnectCallback = callback;
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
        var error: OTError?
        if let connectionId = signal["to"] {
            let connection = OTRN.sharedState.connections[connectionId]
            OTRN.sharedState.session?.signal(withType: signal["type"], string: signal["data"], connection: connection, error: &error)
        } else {
            let connection: OTConnection? = nil
            OTRN.sharedState.session?.signal(withType: signal["type"], string: signal["data"], connection: connection, error: &error)
        }
        if let err = error {
            dispatchErrorViaCallback(callback, error: err)
        } else {
            callback([NSNull()])
        }
    }
    
    @objc func destroyPublisher(_ publisherId: String, callback: @escaping RCTResponseSenderBlock) -> Void {
        DispatchQueue.main.async {
            guard let publisher = OTRN.sharedState.publishers[publisherId] else { callback([NSNull()]); return }
            guard let session = OTRN.sharedState.session else {
                callback([NSNull()]);
                return
            }
            var error: OTError?
            if let isPublishing = OTRN.sharedState.isPublishing[publisherId] {
                if (isPublishing && session.sessionConnectionStatus.rawValue == 1) {
                    session.unpublish(publisher, error: &error)
                }
            }
            guard let err = error else {
                OTRN.sharedState.publisherDestroyedCallbacks[publisherId] = callback;
                return
            }
            self.dispatchErrorViaCallback(callback, error: err)
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
        var sessionInfo: Dictionary<String, Any> = EventUtils.prepareJSSessionEventData(session);
        sessionInfo["connectionStatus"] = session.sessionConnectionStatus.rawValue;
        callback([sessionInfo]);
    }
    
    @objc func enableLogs(_ logLevel: Bool) -> Void {
        self.logLevel = logLevel;
    }
    
    func resetPublisher(_ publisherId: String, publisher: OTPublisher) -> Void {
        publisher.view?.removeFromSuperview()
        OTRN.sharedState.isPublishing[publisherId] = false;
    }
    
    func removeStream(_ streamId: String) -> Void {
        OTRN.sharedState.subscribers.removeValue(forKey: streamId)
        OTRN.sharedState.subscriberStreams.removeValue(forKey: streamId)
    }
    
    func emitEvent(_ event: String, data: Any) -> Void {
        if (self.jsEvents.contains(event) || self.componentEvents.contains(event)) {
            self.sendEvent(withName: event, body: data);
        }
    }
    
    func checkAndEmitStreamPropertyChangeEvent(_ streamId: String, changedProperty: String, oldValue: Any, newValue: Any) {
        guard let stream = OTRN.sharedState.subscriberStreams[streamId] else { return }
        let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream);
        let eventData: Dictionary<String, Any> = EventUtils.prepareStreamPropertyChangedEventData(changedProperty, oldValue: oldValue, newValue: newValue, stream: streamInfo);
        self.emitEvent("\(EventUtils.sessionPreface)streamPropertyChanged", data: eventData)
    }
    
    func dispatchErrorViaCallback(_ callback: RCTResponseSenderBlock, error: OTError) {
        let errorInfo = EventUtils.prepareJSErrorEventData(error);
        callback([errorInfo]);
    }
    
    func printLogs(_ message: String) {
        if (logLevel) {
            print(message)
        }
    }
}

extension OTSessionManager: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        guard let callback = connectCallback else { return }
        callback([NSNull()])
        let sessionInfo = EventUtils.prepareJSSessionEventData(session);
        self.emitEvent("\(EventUtils.sessionPreface)sessionDidConnect", data: sessionInfo);
        printLogs("OTRN: Session connected")
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        let sessionInfo = EventUtils.prepareJSSessionEventData(session);
        self.emitEvent("\(EventUtils.sessionPreface)sessionDidDisconnect", data: sessionInfo);
        guard let callback = disconnectCallback else { return }
        callback([NSNull()]);
        OTRN.sharedState.session?.delegate = nil;
        OTRN.sharedState.session = nil;
        printLogs("OTRN: Session disconnected")
    }
    
    func session(_ session: OTSession, connectionCreated connection: OTConnection) {
        OTRN.sharedState.connections.updateValue(connection, forKey: connection.connectionId)
        let connectionInfo = EventUtils.prepareJSConnectionEventData(connection);
        self.emitEvent("\(EventUtils.sessionPreface)connectionCreated", data: connectionInfo)
        printLogs("OTRN Session: A connection was created \(connection.connectionId)")
    }
    func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
        OTRN.sharedState.connections.removeValue(forKey: connection.connectionId)
        let connectionInfo = EventUtils.prepareJSConnectionEventData(connection);
        self.emitEvent("\(EventUtils.sessionPreface)connectionDestroyed", data: connectionInfo)
        printLogs("OTRN Session: A connection was destroyed")
    }
    
    func session(_ session: OTSession, archiveStartedWithId archiveId: String, name: String?) {
        var archiveInfo: Dictionary<String, String> = [:];
        archiveInfo["archiveId"] = archiveId;
        archiveInfo["name"] = name;
        self.emitEvent("\(EventUtils.sessionPreface)archiveStartedWithId", data: archiveInfo)
        printLogs("OTRN Session: Archive started with \(archiveId)")
    }
    
    func session(_ session: OTSession, archiveStoppedWithId archiveId: String) {
        var archiveInfo: Dictionary<String, String> = [:];
        archiveInfo["archiveId"] = archiveId;
        archiveInfo["name"] = "";
        self.emitEvent("\(EventUtils.sessionPreface)archiveStoppedWithId", data: archiveInfo);
        printLogs("OTRN Session: Archive stopped with \(archiveId)")
    }
    
    func sessionDidBeginReconnecting(_ session: OTSession) {
        self.emitEvent("\(EventUtils.sessionPreface)sessionDidBeginReconnecting", data: [NSNull()])
        printLogs("OTRN Session: Session did begin reconnecting")
    }
    
    func sessionDidReconnect(_ session: OTSession) {
        self.emitEvent("\(EventUtils.sessionPreface)sessionDidReconnect", data: [NSNull()])
        printLogs("OTRN Session: Session reconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        OTRN.sharedState.subscriberStreams.updateValue(stream, forKey: stream.streamId)
        let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream)
        self.emitEvent("\(EventUtils.sessionPreface)streamCreated", data: streamInfo)
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
        printLogs("OTRN: Session streamCreated \(stream.streamId)")
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.sessionPreface)streamDestroyed", data: streamInfo)
        printLogs("OTRN: Session streamDestroyed: \(stream.streamId)")
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        let errorInfo: Dictionary<String, Any> = EventUtils.prepareJSErrorEventData(error);
        self.emitEvent("\(EventUtils.sessionPreface)didFailWithError", data: errorInfo)
        printLogs("OTRN: Session Failed to connect: \(error.localizedDescription)")
    }
    
    func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
        var signalData: Dictionary<String, Any> = [:];
        signalData["type"] = type;
        signalData["data"] = string;
        signalData["connectionId"] = connection?.connectionId;
        self.emitEvent("\(EventUtils.sessionPreface)signal", data: signalData)
        printLogs("OTRN: Session signal received")
    }
}

extension OTSessionManager: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher);
        if (publisherId.count > 0) {
            OTRN.sharedState.isPublishing[publisherId] = true;
            let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream);
            self.emitEvent("\(publisherId):\(EventUtils.publisherPreface)streamCreated", data: streamInfo);
        }
        printLogs("OTRN: Publisher Stream created")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher);
        OTRN.sharedState.isPublishing[publisherId] = false;
        if (publisherId.count > 0) {
            OTRN.sharedState.isPublishing[publisherId] = false;
            let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream);
            self.emitEvent("\(publisherId):\(EventUtils.publisherPreface)streamDestroyed", data: streamInfo);
        }
        OTRN.sharedState.publishers[publisherId] = nil;
        OTRN.sharedState.isPublishing[publisherId] = nil;
        guard let callback = OTRN.sharedState.publisherDestroyedCallbacks[publisherId] else {
            printLogs("OTRN: Publisher Stream destroyed")
            return
        };
        callback([NSNull()]);
        printLogs("OTRN: Publisher Stream destroyed")
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher);
        if (publisherId.count > 0) {
            let errorInfo: Dictionary<String, Any> = EventUtils.prepareJSErrorEventData(error);
            self.emitEvent("\(publisherId):\(EventUtils.publisherPreface)didFailWithError", data: errorInfo)
        }
        printLogs("OTRN: Publisher failed: \(error.localizedDescription)")
    }
}

extension OTSessionManager: OTPublisherKitAudioLevelDelegate {
    func publisher(_ publisher: OTPublisherKit, audioLevelUpdated audioLevel: Float) {
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher);
        if (publisherId.count > 0) {
            self.emitEvent("\(publisherId):\(EventUtils.publisherPreface)audioLevelUpdated", data: audioLevel)
        }
    }
}

extension OTSessionManager: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let stream = subscriberKit.stream {
            let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream);
            self.emitEvent("\(EventUtils.subscriberPreface)subscriberDidConnect", data: streamInfo);
        } else {
            self.emitEvent("\(EventUtils.subscriberPreface)subscriberDidConnect", data: [NSNull()]);
        }
        printLogs("OTRN: Subscriber connected")
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["error"] = EventUtils.prepareJSErrorEventData(error);
        guard let stream = subscriber.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)didFailWithError", data: subscriberInfo)
            return;
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)didFailWithError", data: subscriberInfo)
        printLogs("OTRN: Subscriber failed: \(error.localizedDescription)")
    }
}

extension OTSessionManager: OTSubscriberKitNetworkStatsDelegate {
    func subscriber(_ subscriber: OTSubscriberKit, videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["videoStats"] = EventUtils.prepareSubscriberVideoNetworkStatsEventData(stats);
        guard let stream = subscriber.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)videoNetworkStatsUpdated", data: subscriberInfo);
            return;
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)videoNetworkStatsUpdated", data: subscriberInfo);
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["audioStats"] = EventUtils.prepareSubscriberAudioNetworkStatsEventData(stats);
        guard let stream = subscriber.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)audioNetworkStatsUpdated", data: subscriberInfo);
            return
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)audioNetworkStatsUpdated", data: subscriberInfo);
    }
    
    func subscriberVideoEnabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["reason"] = Utils.convertOTSubscriberVideoEventReasonToString(reason);
        guard let stream = subscriber.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)subscriberVideoEnabled", data: subscriberInfo);
            return;
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)subscriberVideoEnabled", data: subscriberInfo);
        printLogs("OTRN: subscriberVideoEnabled")
    }
    
    func subscriberVideoDisabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["reason"] = Utils.convertOTSubscriberVideoEventReasonToString(reason);
        guard let stream = subscriber.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)subscriberVideoDisabled", data: subscriberInfo);
            return;
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)subscriberVideoDisabled", data: subscriberInfo);
        printLogs("OTRN: subscriberVideoDisabled")
    }
    
    func subscriberVideoDisableWarning(_ subscriber: OTSubscriberKit) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        guard let stream = subscriber.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)subscriberVideoDisableWarning", data: subscriberInfo);
            return;
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)subscriberVideoDisableWarning", data: subscriberInfo);
        printLogs("OTRN: subscriberVideoDisableWarning")
    }
    
    func subscriberVideoDisableWarningLifted(_ subscriber: OTSubscriberKit) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        guard let stream = subscriber.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)subscriberVideoDisableWarningLifted", data: subscriberInfo);
            return;
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)subscriberVideoDisableWarningLifted", data: subscriberInfo);
        printLogs("OTRN: subscriberVideoDisableWarningLifted")
    }
    
    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        guard let stream = subscriber.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)subscriberVideoDataReceived", data: subscriberInfo);
            return
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)subscriberVideoDataReceived", data: subscriberInfo);
    }
    
    func subscriberDidReconnect(toStream subscriber: OTSubscriberKit) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        guard let stream = subscriber.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)subscriberDidReconnect", data: subscriberInfo);
            printLogs("OTRN: subscriberDidReconnect")
            return;
        };
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)subscriberDidReconnect", data: subscriberInfo);
        printLogs("OTRN: subscriberDidReconnect")
    }
    
    func subscriberDidDisconnect(fromStream subscriberKit: OTSubscriberKit) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        guard let stream = subscriberKit.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)subscriberDidDisconnect", data: subscriberInfo);
            printLogs("OTRN: subscriberDidDisconnect")
            return;
        };
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)subscriberDidDisconnect", data: subscriberInfo);
        printLogs("OTRN: Subscriber disconnected")
    }
    
}

extension OTSessionManager: OTSubscriberKitAudioLevelDelegate {
    func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["audioLevel"] = audioLevel;
        guard let stream = subscriber.stream else {
            self.emitEvent("\(EventUtils.subscriberPreface)audioLevelUpdated", data: subscriberInfo);
            return;
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        self.emitEvent("\(EventUtils.subscriberPreface)audioLevelUpdated", data: subscriberInfo);
    }
}
