import Foundation
import OpenTok
import React

@objc public class OTRNSubscriberImpl: NSObject {
    private var sessionId: String?
    private var streamId: String?
    fileprivate weak var strictUIViewContainer:
        OTRNSubscriberComponentView?
    fileprivate var subscriberDelegateHandler: SubscriberDelegateHandler?
    fileprivate var subscriberUIView: UIView?
    fileprivate var subscriberRtcStatsDelegateHandler:
        SubscriberRtcStatsDelegateHandler?
    fileprivate var subscriberAudioLevelDelegateHandler:
        SubscriberAudioLevelDelegateHandler?
    fileprivate var subscriberNetworkStatsDelegateHandler:
        SubscriberNetworkStatsDelegateHandler?
    fileprivate var subscriberCaptionsDelegateHandler:
        SubscriberCaptionsDelegateHandler?

    @objc public var subscriberView: UIView {
        if let subscriberUIView = subscriberUIView {
            return subscriberUIView
        }
        return UIView()
    }

    @objc public init(view: OTRNSubscriberComponentView) {
        super.init()
        self.strictUIViewContainer = view
        subscriberDelegateHandler = SubscriberDelegateHandler(impl: self)
        subscriberRtcStatsDelegateHandler = SubscriberRtcStatsDelegateHandler(
            impl: self)
        subscriberAudioLevelDelegateHandler =
            SubscriberAudioLevelDelegateHandler(impl: self)
        subscriberNetworkStatsDelegateHandler =
            SubscriberNetworkStatsDelegateHandler(impl: self)
        subscriberCaptionsDelegateHandler =
            SubscriberCaptionsDelegateHandler(impl: self)
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
        subscriber.captionsDelegate = subscriberCaptionsDelegateHandler

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

    @objc public func setSubscribeToCaptions(_ subscribeToCaptions: Bool) {
        guard let subscriber = OTRN.sharedState.subscribers[streamId ?? ""]
        else { return }
        subscriber.subscribeToCaptions = subscribeToCaptions
    }

    @objc public func cleanup() {
        if Thread.isMainThread {
            self._cleanupImpl()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?._cleanupImpl()
            }
        }
    }

    private func _cleanupImpl() {
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
        subscriber.captionsDelegate = nil
        OTRN.sharedState.subscribers.removeValue(forKey: streamId)
        self.sessionId = ""
        self.streamId = ""
        self.subscriberUIView = nil
    }
}

private class SubscriberDelegateHandler: NSObject, OTSubscriberDelegate {
    weak var impl: OTRNSubscriberImpl?

    init(impl: OTRNSubscriberImpl) {
        super.init()
        self.impl = impl
    }

    func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        if let stream = subscriber.stream,
            let impl = impl
        {
            let streamInfo: [String: Any] = [
                "stream": EventUtils.prepareJSStreamEventData(stream)
            ]
            impl.strictUIViewContainer?.handleSubscriberConnected(streamInfo)

        }
    }

    func subscriber(
        _ subscriber: OTSubscriberKit, didFailWithError error: OTError
    ) {
        var subscriberInfo: [String: Any] = [
            "error": EventUtils.prepareJSErrorEventData(error)
        ]

        // Always include "stream" key, even if nil (to match TS definition)
        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        } else {
            subscriberInfo["stream"] = NSNull()
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleError(subscriberInfo)
        }
    }

    func subscriberDidDisconnect(fromStream subscriber: OTSubscriberKit) {
        if let stream = subscriber.stream,
            let impl = impl
        {
            let streamInfo: [String: Any] = [
                "stream": EventUtils.prepareJSStreamEventData(stream)
            ]
            impl.strictUIViewContainer?.handleSubscriberDisconnected(streamInfo)
        }
    }

    func subscriberVideoEnabled(
        _ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason
    ) {
        var subscriberInfo: [String: Any] = [
            "reason": Utils.convertOTSubscriberVideoEventReasonToString(reason)
        ]

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        } else {
            subscriberInfo["stream"] = NSNull()
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleVideoEnabled(subscriberInfo)
        }
    }

    func subscriberVideoDisabled(
        _ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason
    ) {
        var subscriberInfo: [String: Any] = [
            "reason": Utils.convertOTSubscriberVideoEventReasonToString(reason)
        ]

        // Always include "stream" key, even if nil (to match TS definition)
        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        } else {
            subscriberInfo["stream"] = NSNull()
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
        } else {
            subscriberInfo["stream"] = NSNull()
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
        } else {
            subscriberInfo["stream"] = NSNull()
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
        } else {
            subscriberInfo["stream"] = NSNull()
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
        } else {
            subscriberInfo["stream"] = NSNull()
        }
        if let impl = impl {
            impl.strictUIViewContainer?.handleReconnected(subscriberInfo)
        }
    }
}

private class SubscriberRtcStatsDelegateHandler: NSObject,
    OTSubscriberKitRtcStatsReportDelegate
{
    weak var impl: OTRNSubscriberImpl?

    init(impl: OTRNSubscriberImpl) {
        super.init()
        self.impl = impl

    }

    func subscriber(_ subscriber: OTSubscriberKit, rtcStatsReport: String) {
        var subscriberInfo: [String: Any] = [
            "jsonStats": rtcStatsReport
        ]
        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        } else {
            subscriberInfo["stream"] = NSNull()
        }
        if let impl = impl {
            impl.strictUIViewContainer?.handleRtcStatsReport(subscriberInfo)
        }
    }
}

private class SubscriberAudioLevelDelegateHandler: NSObject,
    OTSubscriberKitAudioLevelDelegate
{
    weak var impl: OTRNSubscriberImpl?

    init(impl: OTRNSubscriberImpl) {
        super.init()
        self.impl = impl

    }

    func subscriber(
        _ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float
    ) {
        var subscriberInfo: [String: Any] = [
            "audioLevel": audioLevel
        ]
        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        } else {
            subscriberInfo["stream"] = NSNull()
        }
        if let impl = impl {
            impl.strictUIViewContainer?.handleAudioLevel(subscriberInfo)
        }
    }
}

private class SubscriberNetworkStatsDelegateHandler: NSObject,
    OTSubscriberKitNetworkStatsDelegate
{
    weak var impl: OTRNSubscriberImpl?

    init(impl: OTRNSubscriberImpl) {
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

        var subscriberInfo: [String: Any] = [:]
        if let jsonData = try? JSONSerialization.data(
            withJSONObject: statsDict),
            let jsonString = String(data: jsonData, encoding: .utf8)
        {
            subscriberInfo["jsonStats"] = jsonString
        } else {
            subscriberInfo["jsonStats"] = ""
        }

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        } else {
            subscriberInfo["stream"] = NSNull()
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleVideoNetworkStats(subscriberInfo)
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

        var subscriberInfo: [String: Any] = [:]
        if let jsonData = try? JSONSerialization.data(
            withJSONObject: statsDict),
            let jsonString = String(data: jsonData, encoding: .utf8)
        {
            subscriberInfo["jsonStats"] = jsonString
        } else {
            subscriberInfo["jsonStats"] = ""
        }

        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        } else {
            subscriberInfo["stream"] = NSNull()
        }

        if let impl = impl {
            impl.strictUIViewContainer?.handleAudioNetworkStats(subscriberInfo)
        }
    }
}

private class SubscriberCaptionsDelegateHandler: NSObject,
    OTSubscriberKitCaptionsDelegate
{
    weak var impl: OTRNSubscriberImpl?

    init(impl: OTRNSubscriberImpl) {
        super.init()
        self.impl = impl
    }

    func subscriber(
        _ subscriber: OTSubscriberKit, caption text: String, isFinal: Bool
    ) {
        var subscriberInfo: [String: Any] = [
            "text": text,
            "isFinal": isFinal,
        ]
        if let stream = subscriber.stream {
            subscriberInfo["stream"] = EventUtils.prepareJSStreamEventData(
                stream)
        } else {
            subscriberInfo["stream"] = NSNull()
        }
        if let impl = impl {
            impl.strictUIViewContainer?.handleCaptionReceived(subscriberInfo)
        }
    }
}
