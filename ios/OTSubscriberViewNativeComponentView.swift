import Foundation
import OpenTok
import React

@objc public class OTSubscriberViewNativeImpl: NSObject {
    private var sessionId: String?
    private var streamId: String?
    fileprivate weak var strictUIViewContainer:
        OTSubscriberViewNativeComponentView?
    fileprivate var subscriberDelegateHandler: SubscriberDelegateHandler?
    fileprivate var subscriberUIView: UIView?
    fileprivate var subscriberRtcStatsDelegateHandler: SubscriberRtcStatsDelegateHandler?
    fileprivate var subscriberAudioLevelDelegateHandler: SubscriberAudioLevelDelegateHandler?
    fileprivate var subscriberNetworkStatsDelegateHandler: SubscriberNetworkStatsDelegateHandler?

    @objc public var subscriberView: UIView {
        if let subscriberUIView = subscriberUIView {
            return subscriberUIView
        }
        return UIView()
    }

    @objc public init(view: OTSubscriberViewNativeComponentView) {
        super.init()
        self.strictUIViewContainer = view
        subscriberRtcStatsDelegateHandler = SubscriberRtcStatsDelegateHandler(impl: self)
        subscriberAudioLevelDelegateHandler = SubscriberAudioLevelDelegateHandler(impl: self)
        subscriberNetworkStatsDelegateHandler = SubscriberNetworkStatsDelegateHandler(impl: self)
    }

    @objc private func subscribeToStream(
        _ streamId: String, sessionId: String, properties: [String: Any]
    ) {
        guard let stream = OTRN.sharedState.subscriberStreams[streamId] else {
            strictUIViewContainer?.handleError([
                "streamId": streamId,
                "errorMessage":
                    "Error subscribing. Could not find native stream for subscriber.",
            ])
            return
        }

        subscriberDelegateHandler = SubscriberDelegateHandler(impl: self)
        

        guard
            let subscriber = OTSubscriber(
                stream: stream, delegate: subscriberDelegateHandler)
        else {
            strictUIViewContainer?.handleError([
                "streamId": streamId,
                "errorMessage":
                    "Error subscribing. Could not create subscriber.",
            ])
            return
        }

        guard let session = OTRN.sharedState.sessions[sessionId] else {
            strictUIViewContainer?.handleError([
                "streamId": streamId,
                "errorMessage":
                    "Error subscribing. Could not find native session instance.",
            ])
            return
        }

        subscriber.rtcStatsReportDelegate = subscriberRtcStatsDelegateHandler
        subscriber.audioLevelDelegate = subscriberAudioLevelDelegateHandler
        subscriber.networkStatsDelegate = subscriberNetworkStatsDelegateHandler
        
       
        subscriber.subscribeToVideo = Utils.sanitizeBooleanProperty(
            properties["subscribeToVideo"] as Any)
        subscriber.subscribeToCaptions = Utils.sanitizeBooleanProperty(
            properties["subscribeToCaptions"] as Any)
        subscriber.preferredFrameRate = Utils.sanitizePreferredFrameRate(
            properties["preferredFrameRate"] as Any)
        subscriber.preferredResolution = Utils.sanitizePreferredResolution(
            properties["preferredResolution"] as Any)
        
        OTRN.sharedState.subscribers.updateValue(subscriber, forKey: streamId)

        // subscriber.networkStatsDelegate = self
        // subscriber.audioLevelDelegate = self
        // subscriber.captionsDelegate = self
        //     subscriber.rtcStatsReportDelegate = self
        // subscriber.captionsDelegate = self

        var error: OTError?
        session.subscribe(subscriber, error: &error)
        if let err = error {
            strictUIViewContainer?.handleError([
                "streamId": streamId,
                "errorMessage": err.localizedDescription,
            ])
        }

        subscriber.subscribeToAudio = Utils.sanitizeBooleanProperty(
            properties["subscribeToAudio"] as Any)

        if let audioVolume = properties["audioVolume"] as? Double {
            subscriber.audioVolume = audioVolume
        }
        if let subView = subscriber.view {
            subView.frame = strictUIViewContainer?.bounds ?? .zero
            subscriberUIView = subView
        }
    }

    @objc public func createSubscriber(_ properties: NSDictionary) {
        self.sessionId = Utils.sanitizeStringProperty(
            properties["sessionId"] as Any)
        self.streamId = Utils.sanitizeStringProperty(
            properties["streamId"] as Any)

        guard let streamId = self.streamId,
            let stream = OTRN.sharedState.subscriberStreams[streamId]
        else {
            strictUIViewContainer?.handleError([
                "streamId": streamId ?? "",
                "errorMessage": "Could not find stream",
            ])
            return
        }

        //begin
        guard let stream = OTRN.sharedState.subscriberStreams[streamId] else {
            strictUIViewContainer?.handleError([
                "streamId": streamId,
                "errorMessage":
                    "Error subscribing. Could not find native stream for subscriber.",
            ])
            return
        }

        subscriberDelegateHandler = SubscriberDelegateHandler(impl: self)
        

        guard
            let subscriber = OTSubscriber(
                stream: stream, delegate: subscriberDelegateHandler)
        else {
            strictUIViewContainer?.handleError([
                "streamId": streamId,
                "errorMessage":
                    "Error subscribing. Could not create subscriber.",
            ])
            return
        }

        guard let session = OTRN.sharedState.sessions[sessionId ?? ""] else {
            strictUIViewContainer?.handleError([
                "streamId": streamId,
                "errorMessage":
                    "Error subscribing. Could not find native session instance.",
            ])
            return
        }

        subscriber.rtcStatsReportDelegate = subscriberRtcStatsDelegateHandler
        subscriber.audioLevelDelegate = subscriberAudioLevelDelegateHandler
        subscriber.networkStatsDelegate = subscriberNetworkStatsDelegateHandler
       
        subscriber.subscribeToVideo = Utils.sanitizeBooleanProperty(
            properties["subscribeToVideo"] as Any)
        subscriber.subscribeToCaptions = Utils.sanitizeBooleanProperty(
            properties["subscribeToCaptions"] as Any)
        subscriber.preferredFrameRate = Utils.sanitizePreferredFrameRate(
            properties["preferredFrameRate"] as Any)
        subscriber.preferredResolution = Utils.sanitizePreferredResolution(
            properties["preferredResolution"] as Any)
        
        OTRN.sharedState.subscribers.updateValue(subscriber, forKey: streamId)

        // subscriber.networkStatsDelegate = self
        // subscriber.audioLevelDelegate = self
        // subscriber.captionsDelegate = self
        //     subscriber.rtcStatsReportDelegate = self
        // subscriber.captionsDelegate = self

        var error: OTError?
        session.subscribe(subscriber, error: &error)
        if let err = error {
            strictUIViewContainer?.handleError([
                "streamId": streamId,
                "errorMessage": err.localizedDescription,
            ])
        }

        subscriber.subscribeToAudio = Utils.sanitizeBooleanProperty(
            properties["subscribeToAudio"] as Any)

        if let audioVolume = properties["audioVolume"] as? Double {
            subscriber.audioVolume = audioVolume
        }
        if let subView = subscriber.view {
            subView.frame = strictUIViewContainer?.bounds ?? .zero
            subscriberUIView = subView
        }
        //end
//        subscribeToStream(
//            streamId, sessionId: self.sessionId ?? "",
//            properties: properties as! [String: Any])

    }

    @objc public func setSessionId(_ sessionId: String) {
        self.sessionId = sessionId
    }

    @objc public func setStreamId(_ streamId: String) {
        self.streamId = streamId
    }

    @objc public func setSubscribeToAudio(_ subscribeToAudio: Bool) {

        guard let subscriber = OTRN.sharedState.subscribers[streamId ?? ""]
        else {
            return
        }
        subscriber.subscribeToAudio = subscribeToAudio
    }

    @objc public func setSubscribeToVideo(_ subscribeToVideo: Bool) {

        guard let subscriber = OTRN.sharedState.subscribers[streamId ?? ""]
        else { return }
        subscriber.subscribeToVideo = subscribeToVideo

    }

    deinit {
        guard let streamId = self.streamId,
            let subscriber = OTRN.sharedState.subscribers[streamId]
        else {
            return
        }

        subscriber.view?.removeFromSuperview()
        subscriber.delegate = nil
        subscriber.audioLevelDelegate = nil
        subscriber.networkStatsDelegate = nil
       // subscriber.rtcStatsReportDelegate = nil
        subscriberDelegateHandler = nil
       // subscriberRtcStatsDelegateHandler = nil
        subscriberAudioLevelDelegateHandler = nil
        subscriberNetworkStatsDelegateHandler = nil
        OTRN.sharedState.subscribers.removeValue(forKey: streamId)
    }
}

private class SubscriberDelegateHandler: NSObject, OTSubscriberDelegate {
    weak var impl: OTSubscriberViewNativeImpl?

    init(impl: OTSubscriberViewNativeImpl) {
        self.impl = impl
        super.init()
    }

    func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        if let stream = subscriber.stream {
            let streamInfo: [String: Any] = EventUtils.prepareJSStreamEventData(
                stream)
            impl?.strictUIViewContainer?.handleSubscriberConnected(streamInfo)

        } else {
            impl?.strictUIViewContainer?.handleSubscriberConnected([:])
        }

        var error: OTError?
        print("JAY subscriber created for \(subscriber.stream?.streamId ?? "jay error")")
        subscriber.getRtcStatsReport(&error)
        
      
        if let error = error {
           
            print("jay getRtcStatsReport event_failure \(error.localizedDescription)")
            return
        }
        self.impl!.subscriberRtcStatsDelegateHandler?.printHello()        
        }
    

    func subscriber(
        _ subscriber: OTSubscriberKit, didFailWithError error: OTError
    ) {
        var subscriberInfo: [String: Any] = [:]
        subscriberInfo["error"] = EventUtils.prepareJSErrorEventData(error)
        guard let stream = subscriber.stream else {
            impl?.strictUIViewContainer?.handleError(subscriberInfo)
            return
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream)
        impl?.strictUIViewContainer?.handleError(subscriberInfo)

    }

    func subscriberDidDisconnect(fromStream subscriber: OTSubscriberKit) {
        var subscriberInfo: [String: Any] = [:]
        guard let stream = subscriber.stream else {
            impl?.strictUIViewContainer?
                .handleStreamDestroyed(subscriberInfo)

            return
        }
        subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(stream)
        impl?.strictUIViewContainer?.handleStreamDestroyed(subscriberInfo)
    }
}
                                                           
private class SubscriberRtcStatsDelegateHandler: NSObject, OTSubscriberKitRtcStatsReportDelegate {
    weak var impl: OTSubscriberViewNativeImpl?
    
    init(impl: OTSubscriberViewNativeImpl) {
        self.impl = impl
        super.init()
    }
    func printHello() {
        print("Hello from OTSubscriberKitRtcStatsReportDelegate")
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, rtcStatsReport: String) {
        print("rtcStatsReport rtcStatsReport rtcStatsReport rtcStatsReport")
        impl?.strictUIViewContainer?.handleRtcStatsReport(rtcStatsReport)
    }
    deinit {
        print("Deinit from OTSubscriberKitRtcStatsReportDelegate")
    }
}

private class SubscriberAudioLevelDelegateHandler: NSObject, OTSubscriberKitAudioLevelDelegate {
    weak var impl: OTSubscriberViewNativeImpl?
    
    init(impl: OTSubscriberViewNativeImpl) {
        self.impl = impl
        super.init()
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
        //print("Subscriber audio level updated: \(audioLevel)")
        impl?.strictUIViewContainer?.handleAudioLevel([
            "audioLevel": audioLevel
        ])
    }
    
    deinit {
        print("Deinit from OTSubscriberKitAudioLevelDelegate")
    }
}

private class SubscriberNetworkStatsDelegateHandler: NSObject, OTSubscriberKitNetworkStatsDelegate {
    weak var impl: OTSubscriberViewNativeImpl?
    
    init(impl: OTSubscriberViewNativeImpl) {
        self.impl = impl
        super.init()
    }
    
    public func subscriber(_ subscriber: OTSubscriberKit, videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats) {
        print("Subscriber video network stats updated")
        let statsDict: [String: Any] = [
            "videoPacketsLost": stats.videoPacketsLost,
            "videoBytesReceived": stats.videoBytesReceived,
            "videoPacketsReceived": stats.videoPacketsReceived,
            "timestamp": stats.timestamp
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: statsDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            impl?.strictUIViewContainer?.handleVideoNetworkStats(jsonString)
        }
    }
    
    public func subscriber(_ subscriber: OTSubscriberKit, audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats) {
        print("Subscriber audio network stats updated")
        let statsDict: [String: Any] = [
            "audioPacketsLost": stats.audioPacketsLost,
            "audioBytesReceived": stats.audioBytesReceived,
            "audioPacketsReceived": stats.audioPacketsReceived,
            "timestamp": stats.timestamp
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: statsDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            impl?.strictUIViewContainer?.handleAudioNetworkStats(jsonString)
        }
    }
    
    deinit {
        print("Deinit from OTSubscriberKitNetworkStatsDelegate")
    }
}

