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
    fileprivate var subscriberRtcStatsDelegateHandler:
        SubscriberRtcStatsDelegateHandler?
    fileprivate var subscriberAudioLevelDelegateHandler:
        SubscriberAudioLevelDelegateHandler?
    fileprivate var subscriberNetworkStatsDelegateHandler:
        SubscriberNetworkStatsDelegateHandler?

    @objc public var subscriberView: UIView {
        if let subscriberUIView = subscriberUIView {
            return subscriberUIView
        }
        return UIView()
    }

    @objc public init(view: OTSubscriberViewNativeComponentView) {
        super.init()
        self.strictUIViewContainer = view
        subscriberDelegateHandler = SubscriberDelegateHandler(impl: self)
        subscriberRtcStatsDelegateHandler = SubscriberRtcStatsDelegateHandler(
            impl: self)
        subscriberAudioLevelDelegateHandler =
            SubscriberAudioLevelDelegateHandler(impl: self)
        subscriberNetworkStatsDelegateHandler =
            SubscriberNetworkStatsDelegateHandler(impl: self)
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

        subscriber.subscribeToAudio = Utils.sanitizeBooleanProperty(
            properties["subscribeToAudio"] as Any)
        subscriber.subscribeToVideo = Utils.sanitizeBooleanProperty(
            properties["subscribeToVideo"] as Any)
        subscriber.subscribeToCaptions = Utils.sanitizeBooleanProperty(
            properties["subscribeToCaptions"] as Any)
        subscriber.preferredFrameRate = Utils.sanitizePreferredFrameRate(
            properties["preferredFrameRate"] as Any)
        subscriber.preferredResolution = Utils.sanitizePreferredResolution(
            properties["preferredResolution"] as Any)

        var error: OTError?
        session.subscribe(subscriber, error: &error)
        if let err = error {
            strictUIViewContainer?.handleError([
                "streamId": streamId,
                "errorMessage": err.localizedDescription,
            ])
            return
        }
        OTRN.sharedState.subscribers.updateValue(subscriber, forKey: streamId)

        if let audioVolume = properties["audioVolume"] as? Double {
            subscriber.audioVolume = audioVolume
        }
        if let subView = subscriber.view {
            subView.frame = strictUIViewContainer?.bounds ?? .zero
            subscriberUIView = subView
        }
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
        subscriber.rtcStatsReportDelegate = nil
        subscriberDelegateHandler = nil
        subscriberRtcStatsDelegateHandler = nil
        subscriberAudioLevelDelegateHandler = nil
        subscriberNetworkStatsDelegateHandler = nil
        OTRN.sharedState.subscribers.removeValue(forKey: streamId)
    }
}

private class SubscriberDelegateHandler: NSObject, OTSubscriberDelegate {
    weak var impl: OTSubscriberViewNativeImpl?

    init(impl: OTSubscriberViewNativeImpl) {
        super.init()
        self.impl = impl
    }

    func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        if let stream = subscriber.stream,
            let impl = impl
        {
            let streamInfo: [String: Any] = EventUtils.prepareJSStreamEventData(
                stream)
            impl.strictUIViewContainer?.handleSubscriberConnected(streamInfo)

        } else {
            if let impl = impl {
                impl.strictUIViewContainer?.handleSubscriberConnected([:])
            }
        }

    }

    func subscriber(
        _ subscriber: OTSubscriberKit, didFailWithError error: OTError
    ) {
        var subscriberInfo: [String: Any] = [:]
        subscriberInfo["error"] = EventUtils.prepareJSErrorEventData(error)

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleError(subscriberInfo)
        }
    }

    func subscriberDidDisconnect(fromStream subscriber: OTSubscriberKit) {
        var subscriberInfo: [String: Any] = [:]

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleStreamDestroyed(subscriberInfo)
        }
    }

    func subscriberVideoEnabled(
        _ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason
    ) {
        var subscriberInfo: [String: Any] = [:]
        subscriberInfo["reason"] =
            Utils.convertOTSubscriberVideoEventReasonToString(reason)

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleVideoEnabled(subscriberInfo)
        }
    }

    func subscriberVideoDisabled(
        _ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason
    ) {
        var subscriberInfo: [String: Any] = [:]
        subscriberInfo["reason"] =
            Utils.convertOTSubscriberVideoEventReasonToString(reason)

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleVideoDisabled(subscriberInfo)
        }
    }

    func subscriberVideoDisableWarning(_ subscriber: OTSubscriberKit) {
        var subscriberInfo: [String: Any] = [:]

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleVideoDisableWarning(
                subscriberInfo)
        }
    }

    func subscriberVideoDisableWarningLifted(_ subscriber: OTSubscriberKit) {
        var subscriberInfo: [String: Any] = [:]

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleVideoDisableWarningLifted(
                subscriberInfo)
        }
    }

    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
        var subscriberInfo: [String: Any] = [:]

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleVideoDataReceived(subscriberInfo)
        }
    }

    func subscriberDidReconnect(toStream subscriber: OTSubscriberKit) {
        var subscriberInfo: [String: Any] = [:]

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleReconnected(subscriberInfo)
        }
    }
}

private class SubscriberRtcStatsDelegateHandler: NSObject,
    OTSubscriberKitRtcStatsReportDelegate
{
    weak var impl: OTSubscriberViewNativeImpl?

    init(impl: OTSubscriberViewNativeImpl) {
        super.init()
        self.impl = impl

    }

    func subscriber(_ subscriber: OTSubscriberKit, rtcStatsReport: String) {
        if let impl = impl {
            impl.strictUIViewContainer?.handleRtcStatsReport(rtcStatsReport)
        }

    }
}

private class SubscriberAudioLevelDelegateHandler: NSObject,
    OTSubscriberKitAudioLevelDelegate
{
    weak var impl: OTSubscriberViewNativeImpl?

    init(impl: OTSubscriberViewNativeImpl) {
        super.init()
        self.impl = impl

    }

    func subscriber(
        _ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float
    ) {
        if let impl = impl {
            impl.strictUIViewContainer?.handleAudioLevel(audioLevel)
        }
    }
}

private class SubscriberNetworkStatsDelegateHandler: NSObject,
    OTSubscriberKitNetworkStatsDelegate
{
    weak var impl: OTSubscriberViewNativeImpl?

    init(impl: OTSubscriberViewNativeImpl) {
        super.init()
        self.impl = impl
    }

    func subscriber(
        _ subscriber: OTSubscriberKit,
        videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats
    ) {
        let statsDict: [String: Any] = [
            "videoPacketsLost": stats.videoPacketsLost,
            "videoBytesReceived": stats.videoBytesReceived,
            "videoPacketsReceived": stats.videoPacketsReceived,
            "timestamp": stats.timestamp,
        ]

        if let jsonData = try? JSONSerialization.data(
            withJSONObject: statsDict),
            let jsonString = String(data: jsonData, encoding: .utf8),
            let impl = impl
        {
            impl.strictUIViewContainer?.handleVideoNetworkStats(jsonString)
        }
    }

    func subscriber(
        _ subscriber: OTSubscriberKit,
        audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats
    ) {
        let statsDict: [String: Any] = [
            "audioPacketsLost": stats.audioPacketsLost,
            "audioBytesReceived": stats.audioBytesReceived,
            "audioPacketsReceived": stats.audioPacketsReceived,
            "timestamp": stats.timestamp,
        ]

        if let jsonData = try? JSONSerialization.data(
            withJSONObject: statsDict),
            let jsonString = String(data: jsonData, encoding: .utf8),
            let impl = impl
        {
            impl.strictUIViewContainer?.handleAudioNetworkStats(jsonString)
        }
    }
}
