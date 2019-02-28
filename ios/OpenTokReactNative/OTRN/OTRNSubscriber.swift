//
//  OTRNSubscriber.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 2/5/19.
//  Copyright © 2019 TokBox Inc. All rights reserved.
//

import Foundation

class OTRNSubscriber: NSObject {
    var streamId: String
    var jsSubscriberProperties: Dictionary<String, Any>
    var subscriber: OTSubscriber?
    var jsEvents = [String]()
    var componentEvents = [String]()
    var otrnEvents = [String: OTRNEvent]()
    var otrnEventObservers = [String: NSKeyValueObservation]()
    
    init(streamId: String, jsSubscriberProperties: Dictionary<String, Any>, callback: RCTResponseSenderBlock) {
        self.streamId = streamId
        self.jsSubscriberProperties = jsSubscriberProperties
        super.init()
        guard let stream = OTRN.sharedState.subscriberStreams[streamId] else {
            callback(["Error getting stream while subscribing"]);
            return
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        createSubscriber(callback: callback)
    }
    
    private func createSubscriber(callback: RCTResponseSenderBlock) {
        guard let subscriber = self.subscriber else { callback(["Subscriber not found"]); return }
        subscriber.networkStatsDelegate = self
        subscriber.audioLevelDelegate = self
        subscriber.subscribeToAudio = Utils.sanitizeBooleanProperty(jsSubscriberProperties["subscribeToAudio"] as Any)
        subscriber.subscribeToVideo = Utils.sanitizeBooleanProperty(jsSubscriberProperties["subscribeToVideo"] as Any)
        callback([NSNull()])
    }
    
    func setSubscriberEvents(eventType: String, events: [String]) {
        if eventType == "component" {
            self.componentEvents.append(contentsOf: events)
        } else {
            self.jsEvents.append(contentsOf: events)
        }
    }
    
    func removeSubscriberEvents(eventType: String, events: [String]) {
        for event in events {
            if eventType == "component" {
                guard let index = self.componentEvents.index(of: event) else { return }
                self.componentEvents.remove(at: index)
            } else {
                guard let index = self.jsEvents.index(of: event) else { return }
                self.jsEvents.remove(at: index)
            }
        }
    }
    
    func setOTRNEvents() {
        jsEvents.forEach { (event) in
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
    
    func resetOTRNEvents() {
        otrnEventObservers.removeAll()
        otrnEvents.removeAll()
    }
    
    func setEventAndData(event: String, data: Any) {
        guard let otrnEvent = otrnEvents[event] else { return }
        otrnEvent.setData(data: data)
        otrnEvent.setEvent(event: "\(streamId):subscriber:\(event)")
    }
}

extension OTRNSubscriber: OTSubscriberKitDelegate,
OTSubscriberKitNetworkStatsDelegate, OTSubscriberKitAudioLevelDelegate {
    
    func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        guard let stream = subscriber.stream else { return }
        let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream)
        setEventAndData(event: "subscriberDidConnect", data: streamInfo)
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["error"] = EventUtils.prepareJSErrorEventData(error);
        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        }
        setEventAndData(event: "didFailWithError", data: subscriberInfo)
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
        var subscriberInfo: Dictionary<String, Any> = [:]
        subscriberInfo["audioLevel"] = audioLevel
        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream)
        }
        setEventAndData(event: "audioLevelUpdated", data: subscriberInfo)
    }
    
    func subscriberDidReconnect(toStream subscriber: OTSubscriberKit) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        }
        setEventAndData(event: "subscriberDidReconnect", data: subscriberInfo)
    }
    
    func subscriberDidDisconnect(fromStream subscriber: OTSubscriberKit) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        }
        setEventAndData(event: "subscriberDidDisconnect", data: subscriberInfo)
    }
    
    
    func subscriberVideoDisableWarning(_ subscriber: OTSubscriberKit) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        if let stream = subscriber.stream  {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        }
        setEventAndData(event: "subscriberVideoDisableWarning", data: subscriberInfo)
    }
    
    func subscriberVideoDisableWarningLifted(_ subscriber: OTSubscriberKit) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        if let stream = subscriber.stream  {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        }
        setEventAndData(event: "subscriberVideoDisableWarningLifted", data: subscriberInfo)
    }
    
    func subscriberVideoEnabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["reason"] = Utils.convertOTSubscriberVideoEventReasonToString(reason);
        if let stream = subscriber.stream  {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        }
        setEventAndData(event: "subscriberVideoEnabled", data: subscriberInfo)
        
    }
    
    func subscriberVideoDisabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["reason"] = Utils.convertOTSubscriberVideoEventReasonToString(reason);
        if let stream = subscriber.stream  {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        }
        setEventAndData(event: "subscriberVideoDisabled", data: subscriberInfo)
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["audioStats"] = EventUtils.prepareSubscriberAudioNetworkStatsEventData(stats);
        if let stream = subscriber.stream  {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        }
        setEventAndData(event: "audioNetworkStatsUpdated", data: subscriberInfo)
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        subscriberInfo["videoStats"] = EventUtils.prepareSubscriberVideoNetworkStatsEventData(stats);
        if let stream = subscriber.stream  {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        }
        setEventAndData(event: "videoNetworkStatsUpdated", data: subscriberInfo)
    }
    
    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
        var subscriberInfo: Dictionary<String, Any> = [:];
        if let stream = subscriber.stream  {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream);
        }
        setEventAndData(event: "subscriberVideoDataReceived", data: subscriberInfo)
    }
}
