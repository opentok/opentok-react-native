//
//  OTSessionManager.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/12/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation

@objc(OTRNService)
class OTRNService: NSObject {
    
    deinit {
        OTRN.sharedState.subscriberStreams.removeAll();
        OTRN.sharedState.otrnSessions.removeAll();
        OTRN.sharedState.otrnPublishers.removeAll();
        OTRN.sharedState.otrnSubscribers.removeAll();
    }
    
    @objc func initSession(_ apiKey: String, sessionId: String, properties: Dictionary<String, Any>) -> Void {
        let otrnSession: OTRNSession = OTRNSession(apiKey: apiKey, sessionId: sessionId, properties: properties)
        OTRN.sharedState.otrnSessions.updateValue(otrnSession, forKey: sessionId)
    }
    
    @objc func connect(_ sessionId: String, token: String, callback: @escaping RCTResponseSenderBlock) -> Void {
        guard let session = OTRN.sharedState.otrnSessions[sessionId]?.session else {
            callback(["Session not found"]);
            return
        }
        var error: OTError?
        session.connect(withToken: token, error: &error)
        if let connectError = error {
            Utils.dispatchCallbackWithError(callback: callback, error: connectError)
        } else {
            callback([NSNull()])
        }
    }
    
    @objc func initPublisher(_ publisherId: String, properties: Dictionary<String, Any>, callback: @escaping RCTResponseSenderBlock) -> Void {
        DispatchQueue.main.async {
            let otrnPublisher = OTRNPublisher(publisherId: publisherId, jsPublisherProperties: properties, callback: callback)
            OTRN.sharedState.otrnPublishers.updateValue(otrnPublisher, forKey: publisherId)
        }
    }
    
    @objc func publish(_ sessionId: String, publisherId: String, callback: @escaping RCTResponseSenderBlock) -> Void {
        guard let session = OTRN.sharedState.otrnSessions[sessionId]?.session else { callback(["Error finding session"]); return }
        guard let publisher = OTRN.sharedState.otrnPublishers[publisherId]?.publisher else {
            callback(["Error getting publisher"]);
            return
        }
        var error: OTError?
        session.publish(publisher, error: &error)
        if let publishError = error {
            let errorEventData = EventUtils.prepareJSErrorEventData(publishError)
            callback([errorEventData])
        } else {
            callback([NSNull()])
        }
    }
    
    @objc func initSubscriber(_ streamId: String, properties: Dictionary<String, Any>, callback: @escaping RCTResponseSenderBlock) -> Void {
        DispatchQueue.main.async {
            let otrnSubscriber = OTRNSubscriber(streamId: streamId, jsSubscriberProperties: properties, callback: callback)
            OTRN.sharedState.otrnSubscribers.updateValue(otrnSubscriber, forKey: streamId)
        }
    }
    @objc func subscribe(_ sessionId: String, streamId: String, properties: Dictionary<String, Any>, callback: @escaping RCTResponseSenderBlock) -> Void {
        DispatchQueue.main.async {
            guard let session = OTRN.sharedState.otrnSessions[sessionId]?.session else { callback(["Error finding session"]); return }
            guard let subscriber = OTRN.sharedState.otrnSubscribers[streamId]?.subscriber else {  callback(["Error finding native subscriber"]); return }
            var error: OTError?
            session.subscribe(subscriber, error: &error)
            if let err = error {
                Utils.dispatchCallbackWithError(callback: callback, error: err)
            } else  {
                callback([NSNull(), streamId])
            }
        }
    }
    
    @objc func removeSubscriber(_ streamId: String, callback: @escaping RCTResponseSenderBlock) -> Void {
        DispatchQueue.main.async {
            guard let subscriber = OTRN.sharedState.otrnSubscribers[streamId]?.subscriber else {
                callback(["There was an error finding the subscriber"])
                return
            }
            subscriber.view?.removeFromSuperview();
            subscriber.delegate = nil;
            OTRN.sharedState.otrnSubscribers.removeValue(forKey: streamId)
            OTRN.sharedState.subscriberStreams.removeValue(forKey: streamId)
            callback([NSNull()])
        }
    }
    
    @objc func disconnectSession(_ sessionId: String, callback: RCTResponseSenderBlock) -> Void {
        guard let otrnSession = OTRN.sharedState.otrnSessions[sessionId] else {
            callback(["Native session instance not found"])
            return
        }
        var error: OTError?
        otrnSession.session?.disconnect(&error)
        if let disconnectError = error {
            Utils.dispatchCallbackWithError(callback: callback, error: disconnectError)
        } else {
            callback([NSNull()])
        }
    }
    
    @objc func publishAudio(_ publisherId: String, pubAudio: Bool) -> Void {
        guard let otrnPublisher = OTRN.sharedState.otrnPublishers[publisherId] else { return }
        otrnPublisher.publisher?.publishAudio = pubAudio
    }
    
    @objc func publishVideo(_ publisherId: String, pubVideo: Bool) -> Void {
        guard let otrnPublisher = OTRN.sharedState.otrnPublishers[publisherId] else { return }
        otrnPublisher.publisher?.publishVideo = pubVideo
    }
    
    @objc func subscribeToAudio(_ streamId: String, subAudio: Bool) -> Void {
        guard let otrnSubscriber = OTRN.sharedState.otrnSubscribers[streamId] else { return }
        otrnSubscriber.subscriber?.subscribeToAudio = subAudio
    }
    
    @objc func subscribeToVideo(_ streamId: String, subVideo: Bool) -> Void {
        guard let otrnSubscriber = OTRN.sharedState.otrnSubscribers[streamId] else { return }
        otrnSubscriber.subscriber?.subscribeToVideo = subVideo;
    }
    
    @objc func changeCameraPosition(_ publisherId: String, cameraPosition: String) -> Void {
        guard let otrnPublisher = OTRN.sharedState.otrnPublishers[publisherId] else { return }
        otrnPublisher.publisher?.cameraPosition = cameraPosition == "front" ? .front : .back;
    }
    
    @objc func setSessionEvents(_ sessionId: String, eventType: String, events: [String]) -> Void {
        guard let otrnSession = OTRN.sharedState.otrnSessions[sessionId] else { return }
        otrnSession.setSessionEvents(eventType: eventType, events: events)
    }
    
    @objc func removeSessionEvents(_ sessionId: String, eventType: String, events: [String]) -> Void {
        guard let otrnSession = OTRN.sharedState.otrnSessions[sessionId] else { return }
        otrnSession.removeSessionEvents(eventType: eventType, events: events)
    }
    
    @objc func setPublisherEvents(_ publisherId: String, eventType: String, events: [String]) -> Void {
        guard let otrnPublisher = OTRN.sharedState.otrnPublishers[publisherId] else { return }
        otrnPublisher.setPublisherEvents(eventType: eventType, events: events)
    }
    
    @objc func removePublisherEvents(_ publisherId: String, eventType: String, events: [String]) -> Void {
        guard let otrnPublisher = OTRN.sharedState.otrnPublishers[publisherId] else { return }
        otrnPublisher.removePublisherEvents(eventType: eventType, events: events)
    }
    
    @objc func setSubscriberEvents(_ subscriberId: String, eventType: String, events: [String]) -> Void {
        guard let otrnSubscriber = OTRN.sharedState.otrnSubscribers[subscriberId] else { return }
        otrnSubscriber.setSubscriberEvents(eventType: eventType, events: events)
    }
    
    @objc func removeSubscriberEvents(_ subscriberId: String, eventType: String, events: [String]) -> Void {
        guard let otrnSubscriber = OTRN.sharedState.otrnSubscribers[subscriberId] else { return }
        otrnSubscriber.removeSubscriberEvents(eventType: eventType, events: events)
    }
    
    @objc func sendSignal(_ sessionId: String, signal: Dictionary<String, String>, callback: RCTResponseSenderBlock ) -> Void {
        guard let otrnSession = OTRN.sharedState.otrnSessions[sessionId] else {
            callback(["Issue sending signal - session not found"])
            return
        }
        otrnSession.sendSignal(signal: signal, callback: callback)
    }
    
    @objc func destroyPublisher(_ sessionId: String, publisherId: String, callback: @escaping RCTResponseSenderBlock) -> Void {
        DispatchQueue.main.async {
            guard let otrnPublisher = OTRN.sharedState.otrnPublishers[publisherId] else { callback([NSNull()]); return }
            guard let publisher = otrnPublisher.publisher else { callback([NSNull()]); return }
            guard let session = OTRN.sharedState.otrnSessions[sessionId]?.session else { callback([NSNull()]); return }
            var error: OTError?
            if (otrnPublisher.isPublishing && session.sessionConnectionStatus.rawValue == 1) {
                session.unpublish(publisher, error: &error)
            }
            if let destroyPublisherError = error {
                Utils.dispatchCallbackWithError(callback: callback, error: destroyPublisherError)
            } else {
                otrnPublisher.publisherDestroyedCallback = callback
            }
            otrnPublisher.isPublishing = false
            OTRN.sharedState.otrnPublishers.removeValue(forKey: publisherId)
        }
    }
    
    @objc func getSessionInfo(_ sessionId: String, callback: RCTResponseSenderBlock) -> Void {
        guard let session = OTRN.sharedState.otrnSessions[sessionId]?.session else { callback([NSNull()]); return }
        var sessionInfo: Dictionary<String, Any> = EventUtils.prepareJSSessionEventData(session)
        sessionInfo["connectionStatus"] = session.sessionConnectionStatus.rawValue
        callback([sessionInfo])
    }
    
    @objc func enableLogs(_ logLevel: Bool) -> Void {
        OTRN.sharedState.logLevel = logLevel
    }

}
