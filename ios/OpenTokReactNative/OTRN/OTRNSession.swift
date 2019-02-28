//
//  OTRNSession.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/28/19.
//  Copyright © 2019 TokBox Inc. All rights reserved.
//

import Foundation

class OTRNSession: NSObject {
    var apiKey: String
    var sessionId: String
    var settings: OTSessionSettings?
    var sessionProperties: Dictionary<String, Any>
    var session: OTSession?
    var isConnected: Bool = false
    var componentEvents = [String]()
    var jsEvents = [String]()
    var connections = [String: OTConnection]()
    var nativeOTRNEvents = [String: OTRNEvent]()
    var nativeOTRNEventObservers = [String: NSKeyValueObservation]()
    var componentOTRNEvents = [String: OTRNEvent]()
    var componentOTRNEventObservers = [String: NSKeyValueObservation]()
    var streamObservers = [String: [NSKeyValueObservation]]()
    
    init(apiKey: String, sessionId: String, properties: [String: Any]) {
        self.apiKey = apiKey
        self.sessionId = sessionId
        self.sessionProperties = properties
        super.init()
        self.settings = Utils.sanitizeSessionSettings(properties)
        initSession()
    }
    
    private func initSession() {
        guard let sessionSettings = settings else {
            session = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self)
            return
        }
        session = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self, settings: sessionSettings)
    }
    

    func setSessionEvents(eventType: String, events: [String]) {
        if eventType == "component" {
            self.componentEvents.append(contentsOf: events)
        } else {
            self.jsEvents.append(contentsOf: events)
        }
        setOTRNEvents(eventType: eventType)
    }
    
    func removeSessionEvents(eventType: String, events: [String]) {
        if eventType == "component" {
            for event in events {
                if let i = self.componentEvents.index(of: event) {
                    self.componentEvents.remove(at: i)
                }
            }
        } else {
            for event in events {
                if let i = self.jsEvents.index(of: event) {
                    self.jsEvents.remove(at: i)
                }
            }
        }
        resetOTRNEvents(eventType: eventType)
    }
    
    func sendSignal(signal: Dictionary<String, String>, callback: RCTResponseSenderBlock) -> Void {
        let connId = signal["to"]
        var connection: OTConnection?
        if let connectionId = connId {
            connection = connections[connectionId]
        }
        var error: OTError?
       session?.signal(withType: signal["type"], string: signal["data"], connection: connection, error: &error)
        if let signalError = error {
            Utils.dispatchCallbackWithError(callback: callback, error: signalError)
        } else {
            callback([NSNull()])
        }
    }
    
    func setOTRNEvents(eventType: String) {
        var events: [String], otrnEvents: [String: OTRNEvent], otrnEventObservers: [String: NSKeyValueObservation]
        if (eventType == "component") {
            events = componentEvents
            otrnEvents = componentOTRNEvents
            otrnEventObservers = componentOTRNEventObservers
        } else {
            events = jsEvents
            otrnEvents = nativeOTRNEvents
            otrnEventObservers = nativeOTRNEventObservers
        }
        events.forEach { (event) in
            let otrnEvent = OTRNEvent()
            let otrnEventObserver = otrnEvent.observe(\.event, options: [.old, .new], changeHandler: { (object, value) in
                guard let newValue = value.newValue else { return }
                if (newValue.count > 0) {
                    guard let data = object.data else { return }
                    OTRNEventEmitter().sendEvent(withName: newValue, body: data)
                }
            })
            otrnEvents.updateValue(otrnEvent, forKey: event)
            otrnEventObservers.updateValue(otrnEventObserver, forKey: event)
        }
    }
    
    func resetOTRNEvents(eventType: String) {
        if (eventType == "component") {
            componentOTRNEvents.removeAll()
            componentOTRNEventObservers.removeAll()
        } else {
            nativeOTRNEventObservers.removeAll()
            nativeOTRNEvents.removeAll()
        }
    }
    
    func setEventAndData(event: String, data: Any) {
        guard let componentOTRNEvent = componentOTRNEvents[event] else { return }
        componentOTRNEvent.setData(data: data)
        componentOTRNEvent.setEvent(event: "\(sessionId):session:\(event)")
        guard let otrnEvent = nativeOTRNEvents[event] else { return }
        otrnEvent.setData(data: data)
        otrnEvent.setEvent(event: "\(sessionId):session:\(event)")
    }
    
    func checkAndEmitStreamPropertyChangeEvent(_ streamId: String, changedProperty: String, oldValue: Any, newValue: Any) {
        guard let stream = OTRN.sharedState.subscriberStreams[streamId] else { return }
        let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream);
        let eventData: Dictionary<String, Any> = EventUtils.prepareStreamPropertyChangedEventData(changedProperty, oldValue: oldValue, newValue: newValue, stream: streamInfo);
        OTRNEventEmitter().sendEvent(withName: "\(sessionId)session:streamPropertyChanged", body: eventData)
    }
}

extension OTRNSession: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        isConnected = true
        let sessionInfo = EventUtils.prepareJSSessionEventData(session)
        setEventAndData(event: "sessionDidConnect", data: sessionInfo)
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        isConnected = false
        let sessionInfo = EventUtils.prepareJSSessionEventData(session)
        setEventAndData(event: "sessionDidDisconnect", data: sessionInfo)
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        let errorEventData = EventUtils.prepareJSErrorEventData(error)
        setEventAndData(event: "didFailWithError", data: errorEventData)
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        OTRN.sharedState.subscriberStreams.updateValue(stream, forKey: stream.streamId)
        let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream);
        setEventAndData(event: "streamCreated", data: streamInfo)
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
        streamObservers.updateValue([hasAudioObservation, hasVideoObservation, videoDimensionsObservation, videoTypeObservation], forKey: stream.streamId)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        OTRN.sharedState.subscriberStreams.removeValue(forKey: stream.streamId)
        let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream);
        setEventAndData(event: "streamDestroyed", data: streamInfo)
    }
    
    func session(_ session: OTSession, connectionCreated connection: OTConnection) {
        connections.updateValue(connection, forKey: connection.connectionId)
        let connectionInfo = EventUtils.prepareJSConnectionEventData(connection);
        setEventAndData(event: "connectionCreated", data: connectionInfo)
    }
    
    func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
        connections.removeValue(forKey: connection.connectionId)
        let connectionInfo = EventUtils.prepareJSConnectionEventData(connection);
        setEventAndData(event: "connectionDestroyed", data: connectionInfo)
    }
    
    func sessionDidReconnect(_ session: OTSession) {
        setEventAndData(event: "sessionDidReconnect", data: [NSNull()])
    }
    
    func sessionDidBeginReconnecting(_ session: OTSession) {
        setEventAndData(event: "sessionDidBeginReconnecting", data: [NSNull()])
    }
    
    func session(_ session: OTSession, archiveStartedWithId archiveId: String, name: String?) {
        var archiveInfo: Dictionary<String, String> = [:];
        archiveInfo["archiveId"] = archiveId;
        archiveInfo["name"] = name;
        setEventAndData(event: "archiveStartedWithId", data: archiveInfo)
    }
    
    func session(_ session: OTSession, archiveStoppedWithId archiveId: String) {
        var archiveInfo: Dictionary<String, String> = [:];
        archiveInfo["archiveId"] = archiveId;
        archiveInfo["name"] = "";
        setEventAndData(event: "archiveStoppedWithId", data: archiveInfo)
    }
    
    func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
        var signalData: Dictionary<String, Any> = [:];
        signalData["type"] = type;
        signalData["data"] = string;
        signalData["connectionId"] = connection?.connectionId;
        setEventAndData(event: "signal", data: signalData)
    }
}
