//
//  OTRNPublisher.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/28/19.
//  Copyright © 2019 TokBox Inc. All rights reserved.
//

import Foundation

class OTRNPublisher: NSObject {
    var publisherId: String
    var publisher: OTPublisher?
    var sessionId: String?
    var jsPublisherProperties: [String: Any]
    var isPublishing: Bool = false
    var componentEvents = [String]()
    var jsEvents = [String]()
    var publisherDestroyedCallback: RCTResponseSenderBlock?
    var otrnEvents = [String: OTRNEvent]()
    var otrnEventObservers = [String: NSKeyValueObservation]()
    
    init(publisherId: String, jsPublisherProperties: [String: Any], callback: @escaping RCTResponseSenderBlock) {
        self.publisherId = publisherId
        self.jsPublisherProperties = jsPublisherProperties
        super.init()
        let publisherSettings = createPublisherSettings()
        publisher = OTPublisher(delegate: self, settings: publisherSettings)
        let handler: (String) -> Void = {
            if $0.count > 0 {
                callback([$0]) 
            } else {
                callback([NSNull()])
            }
        }
        setPublisherProperties(callback: handler)
    }
    
    private func createPublisherSettings() -> OTPublisherSettings {
        let publisherSettings = OTPublisherSettings()
        publisherSettings.videoTrack = Utils.sanitizeBooleanProperty(jsPublisherProperties["videoTrack"] as Any)
        publisherSettings.audioTrack = Utils.sanitizeBooleanProperty(jsPublisherProperties["audioTrack"] as Any)
        if let audioBitrate = jsPublisherProperties["audioBitrate"] as? Int {
            publisherSettings.audioBitrate = Int32(audioBitrate)
        }
        publisherSettings.cameraFrameRate = Utils.sanitizeFrameRate(jsPublisherProperties["frameRate"] as Any)
        publisherSettings.cameraResolution = Utils.sanitizeCameraResolution(jsPublisherProperties["resolution"] as Any)
        publisherSettings.name = jsPublisherProperties["name"] as? String
        return publisherSettings
    }
    
    private func setPublisherProperties(callback: (String) -> Void) {
        if let videoSource = jsPublisherProperties["videoSource"] as? String, videoSource == "screen" {
            guard let screenView = RCTPresentedViewController()?.view else {
                callback("Error setting screenshare")
                return
            }
            publisher?.videoType = .screen;
            publisher?.videoCapture = OTRNScreenCapturer(withView: (screenView))
        } else if let cameraPosition = jsPublisherProperties["cameraPosition"] as? String {
            publisher?.cameraPosition = cameraPosition == "front" ? .front : .back
        }
        publisher?.audioFallbackEnabled = Utils.sanitizeBooleanProperty(jsPublisherProperties["audioFallbackEnabled"] as Any)
        publisher?.publishAudio = Utils.sanitizeBooleanProperty(jsPublisherProperties["publishAudio"] as Any)
        publisher?.publishVideo = Utils.sanitizeBooleanProperty(jsPublisherProperties["publishVideo"] as Any)
        publisher?.audioLevelDelegate = self
        callback("")
    }
    
    func setPublisherEvents(eventType: String, events: [String]) {
        if eventType == "component" {
            self.componentEvents.append(contentsOf: events)
        } else {
            self.jsEvents.append(contentsOf: events)
            setOTRNEvents()
        }
        
    }
    
    func removePublisherEvents(eventType: String, events: [String]) {
        for event in events {
            if eventType == "component" {
                guard let index = self.componentEvents.index(of: event) else { return }
                self.componentEvents.remove(at: index)
            } else {
                guard let index = self.jsEvents.index(of: event) else { return }
                self.jsEvents.remove(at: index)
            }
        }
        resetOTRNEvents()
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
        otrnEvent.setEvent(event: "\(publisherId):publisher:\(event)")
    }

}

extension OTRNPublisher: OTPublisherKitDelegate, OTPublisherKitAudioLevelDelegate {
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        let errorEventData = EventUtils.prepareJSErrorEventData(error)
        setEventAndData(event: "didFailWithError", data: errorEventData)
    }
    
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        isPublishing = true
        let streamInfo = EventUtils.prepareJSStreamEventData(stream);
        setEventAndData(event: "streamCreated", data: streamInfo)

    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        isPublishing = false
        let streamInfo = EventUtils.prepareJSStreamEventData(stream);
        setEventAndData(event: "streamDestroyed", data: streamInfo)
        guard let callback = publisherDestroyedCallback else { return };
        callback([NSNull()]);
    }

    func publisher(_ publisher: OTPublisherKit, audioLevelUpdated audioLevel: Float) {
        setEventAndData(event: "audioLevelUpdated", data: audioLevel)
    }
}

