import Foundation
import OpenTok
import React

@objc public class OTRNPublisherImpl: NSObject {
    private var currentSession: OTSession?
    private var sessionId: String?
    fileprivate var publisherId: String?
    fileprivate weak var strictUIViewContainer:
        OTRNPublisherComponentView?
    fileprivate var publisherDelegateHandler: PublisherDelegateHandler?
    fileprivate var publisherAudioLevelDelegateHandler:
        PublisherAudioLevelDelegateHandler?
    fileprivate var publisherNetworkStatsDelegateHandler:
        PublisherNetworkStatsDelegateHandler?
    fileprivate var publisherRtcStatsDelegateHandler:
        PublisherRtcStatsDelegateHandler?

    fileprivate var publisherUIView: UIView?

    @objc public var publisherView: UIView {
        if let publisherUIView = publisherUIView {
            return publisherUIView
        }
        return UIView()
    }

    @objc public init(
        view: OTRNPublisherComponentView
    ) {
        super.init()
        self.strictUIViewContainer = view
        publisherDelegateHandler = PublisherDelegateHandler(impl: self)
        publisherAudioLevelDelegateHandler = PublisherAudioLevelDelegateHandler(
            impl: self
        )
        publisherNetworkStatsDelegateHandler =
            PublisherNetworkStatsDelegateHandler(impl: self)
        publisherRtcStatsDelegateHandler = PublisherRtcStatsDelegateHandler(
            impl: self
        )
    }

    @objc public func createPublisher(_ properties: NSDictionary) {

        let settings = OTPublisherSettings()

        settings.videoTrack = Utils.sanitizeBooleanProperty(
            properties["videoTrack"] as Any
        )
        settings.audioTrack = Utils.sanitizeBooleanProperty(
            properties["audioTrack"] as Any
        )
        if let audioBitrate = properties["audioBitrate"] as? Int32 {
            settings.audioBitrate = audioBitrate
        }
        settings.cameraFrameRate = Utils.sanitizeFrameRate(
            properties["frameRate"] as Any
        )
        settings.cameraResolution = Utils.sanitizeCameraResolution(
            properties["resolution"] as? String ?? "MEDIUM"
        )
        settings.enableOpusDtx = Utils.sanitizeBooleanProperty(
            properties["enableDtx"] as Any
        )
        settings.name = properties["name"] as? String
        settings.publisherAudioFallbackEnabled =
            Utils.sanitizeBooleanProperty(
                properties["publisherAudioFallback"] as Any
            )
        settings.subscriberAudioFallbackEnabled =
            Utils.sanitizeBooleanProperty(
                properties["subscriberAudioFallback"] as Any
            )
        settings.videoCapture?.videoContentHint =
            Utils.convertVideoContentHint(properties["videoContentHint"] as Any)
        settings.scalableScreenshare = Utils.sanitizeBooleanProperty(
            properties["scalableScreenshare"] as Any
        )

        self.publisherId = Utils.sanitizeStringProperty(
            properties["publisherId"] as Any
        )

        guard let publisherId = self.publisherId else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Publisher ID is not set",
            ])
            return
        }

        guard
            let publisher = OTPublisher(
                delegate: publisherDelegateHandler,
                settings: settings
            )
        else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message":
                    "There was an error creating the native publisher instance",
            ])
            return
        }

        publisher.audioLevelDelegate = publisherAudioLevelDelegateHandler
        publisher.networkStatsDelegate = publisherNetworkStatsDelegateHandler
        publisher.rtcStatsReportDelegate = publisherRtcStatsDelegateHandler

        OTRN.sharedState.publishers.updateValue(publisher, forKey: publisherId)

        if let videoSource = properties["videoSource"] as? String,
            videoSource == "screen"
        {
            guard let screenView = RCTPresentedViewController()?.view else {
                strictUIViewContainer?.handleError([
                    "code": "OTPublisherError",
                    "message":
                        "There was an error setting the videoSource as screen",
                ])
                return
            }
            publisher.videoType = .screen
            publisher.videoCapture = OTScreenCapture(view: screenView)
        } else if let cameraPosition = properties["cameraPosition"] as? String {
            publisher.cameraPosition =
                cameraPosition == "front" ? .front : .back
        }

        publisher.cameraTorch = Utils.sanitizeBooleanProperty(
            properties["cameraTorch"] as Any
        )
        publisher.cameraZoomFactor = Utils.sanitizeCameraZoomFactor(
            properties["cameraZoomFactor"] as Any
        )
        publisher.audioFallbackEnabled = Utils.sanitizeBooleanProperty(
            properties["audioFallbackEnabled"] as Any
        )
        publisher.publishAudio = Utils.sanitizeBooleanProperty(
            properties["publishAudio"] as Any
        )
        publisher.publishVideo = Utils.sanitizeBooleanProperty(
            properties["publishVideo"] as Any
        )
        publisher.publishCaptions = Utils.sanitizeBooleanProperty(
            properties["publishCaptions"] as Any
        )

        if let pubView = publisher.view {
            pubView.frame = strictUIViewContainer?.bounds ?? .zero
            publisherUIView = pubView
        }

    }
    @objc public func setSessionId(_ sessionId: String) {
        self.sessionId = sessionId
    }

    @objc public func setPublisherId(_ publisherId: String) {
        self.publisherId = publisherId
    }

    @objc public func setPublishAudio(_ publishAudio: Bool) {
        guard let publisherId = self.publisherId else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Publisher ID is not set",
            ])
            return
        }

        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Could not find publisher instance",
            ])
            return
        }

        publisher.publishAudio = publishAudio
    }

    @objc public func setPublishVideo(_ publishVideo: Bool) {
        guard let publisherId = self.publisherId else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Publisher ID is not set",
            ])
            return
        }

        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Could not find publisher instance",
            ])
            return
        }

        publisher.publishVideo = publishVideo
    }

    @objc public func setCameraTorch(_ cameraTorch: Bool) {
        guard let publisherId = self.publisherId else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Publisher ID is not set",
            ])
            return
        }

        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Could not find publisher instance",
            ])
            return
        }

        publisher.cameraTorch = cameraTorch
    }

    @objc public func setCameraZoomFactor(_ cameraZoomFactor: Float) {
        guard let publisherId = self.publisherId else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Publisher ID is not set",
            ])
            return
        }

        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Could not find publisher instance",
            ])
            return
        }

        publisher.cameraZoomFactor = cameraZoomFactor
    }

    @objc public func setVideoContentHint(_ videoContentHint: String) {
        guard let publisherId = self.publisherId else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Publisher ID is not set",
            ])
            return
        }

        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            strictUIViewContainer?.handleError([
                "code": "OTPublisherError",
                "message": "Could not find publisher instance",
            ])
            return
        }

        publisher.videoCapture?.videoContentHint =
            Utils.convertVideoContentHint(videoContentHint)
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

        guard let publisherId = self.publisherId,
            let publisher = OTRN.sharedState.publishers[publisherId]
        else { return }

        var error: OTError?

        if let isPublishing = OTRN.sharedState.isPublishing[publisherId] {
            if isPublishing {
                if let sessionId = publisher.session?.sessionId {
                    guard let session = OTRN.sharedState.sessions[sessionId]
                    else {
                        self.strictUIViewContainer?.handleError([
                            "code": "OTPublisherError",
                            "message":
                                "Error destroying publisher. Could not find native session instance",
                        ])
                        return
                    }
                    if session.sessionConnectionStatus == .connected {
                        session.unpublish(publisher, error: &error)
                    }
                }
            }
        }

        if let err = error {
            self.strictUIViewContainer?.handleError([
                "code": String(err.code),
                "message": err.localizedDescription,
            ])
        } else {
            // Clean up publisher resources
            publisher.view?.removeFromSuperview()
            publisher.delegate = nil
            publisher.audioLevelDelegate = nil
            publisher.networkStatsDelegate = nil
            publisher.rtcStatsReportDelegate = nil
            OTRN.sharedState.publishers[publisherId] = nil
            OTRN.sharedState.isPublishing[publisherId] = nil
            self.publisherId = ""
            self.sessionId = ""
            self.currentSession = nil
            self.publisherUIView = nil
        }

    }

}

private class PublisherDelegateHandler: NSObject, OTPublisherKitDelegate {

    weak var impl: OTRNPublisherImpl?

    init(impl: OTRNPublisherImpl) {
        super.init()
        self.impl = impl
    }

    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream)
    {
        OTRN.sharedState.publisherStreams.updateValue(
            stream,
            forKey: stream.streamId
        )
        OTRN.sharedState.subscriberStreams.updateValue(
            stream,
            forKey: stream.streamId
        )
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher)
        if !publisherId.isEmpty,
            let impl = impl
        {
            OTRN.sharedState.isPublishing[publisherId] = true
            var streamInfo: [String: Any] = EventUtils.prepareJSStreamEventData(
                stream
            )
            streamInfo["publisherId"] = publisherId
            Utils.setStreamObservers(stream: stream, isPublisherStream: true)
            impl.strictUIViewContainer?.handleStreamCreated(streamInfo)
        }
    }

    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError)
    {
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher)
        if !publisherId.isEmpty, let impl = impl {
            let errorInfo: [String: Any] = EventUtils.prepareJSErrorEventData(
                error
            )
            impl.strictUIViewContainer?.handleError(errorInfo)
        }
    }

    func publisher(
        _ publisher: OTPublisherKit,
        streamDestroyed stream: OTStream
    ) {
        OTRN.sharedState.streamObservers.removeValue(forKey: stream.streamId)
        OTRN.sharedState.publisherStreams.removeValue(forKey: stream.streamId)
        OTRN.sharedState.subscriberStreams.removeValue(forKey: stream.streamId)
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher)
        if !publisherId.isEmpty {
            OTRN.sharedState.isPublishing[publisherId] = false
            var streamInfo: [String: Any] = EventUtils.prepareJSStreamEventData(
                stream
            )
            streamInfo["publisherId"] = publisherId
            OTRN.sharedState.publishers[publisherId] = nil
            impl?.strictUIViewContainer?.handleStreamDestroyed(streamInfo)
        }
    }

    func publisher(_ publisher: OTPublisherKit, muteForced: Bool) {
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher)
        if !publisherId.isEmpty, let impl = impl {
            impl.strictUIViewContainer?.handleMuteForced()
        }
    }

    func publisherVideoDisableWarning(_ publisher: OTPublisherKit) {
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher)
        if !publisherId.isEmpty, let impl = impl {
            impl.strictUIViewContainer?.handleVideoDisableWarning()
        }
    }

    func publisherVideoDisableWarningLifted(_ publisher: OTPublisherKit) {
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher)
        if !publisherId.isEmpty, let impl = impl {
            impl.strictUIViewContainer?.handleVideoDisableWarningLifted()
        }
    }

    func publisherVideoEnabled(
        _ publisher: OTPublisherKit,
        reason: OTPublisherVideoEventReason
    ) {
        var publisherInfo: [String: Any] = [:]
        publisherInfo["reason"] =
            Utils.convertOTPublisherVideoEventReasonToString(reason)
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher)
        if !publisherId.isEmpty, let impl = impl {
            impl.strictUIViewContainer?.handleVideoEnabled()  //TODO send publisherInfo?
        }
    }
    func publisherVideoDisabled(
        _ publisher: OTPublisherKit,
        reason: OTPublisherVideoEventReason
    ) {
        var publisherInfo: [String: Any] = [:]
        publisherInfo["reason"] =
            Utils.convertOTPublisherVideoEventReasonToString(reason)
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher)
        if !publisherId.isEmpty, let impl = impl {
            impl.strictUIViewContainer?
                .handleVideoDisabled()  //TODO send publisherInfo?
        }

    }
}

private class PublisherAudioLevelDelegateHandler: NSObject,
    OTPublisherKitAudioLevelDelegate
{
    weak var impl: OTRNPublisherImpl?

    init(impl: OTRNPublisherImpl) {
        super.init()
        self.impl = impl
    }

    func publisher(
        _ publisher: OTPublisherKit,
        audioLevelUpdated audioLevel: Float
    ) {
        let publisherId = Utils.getPublisherId(publisher as! OTPublisher)
        if !publisherId.isEmpty,
            let impl = impl
        {
            impl.strictUIViewContainer?.handleAudioLevel(audioLevel)
        }
    }
}

private class PublisherNetworkStatsDelegateHandler: NSObject,
    OTPublisherKitNetworkStatsDelegate
{
    weak var impl: OTRNPublisherImpl?

    init(impl: OTRNPublisherImpl) {
        super.init()
        self.impl = impl
    }

    func publisher(
        _ publisher: OTPublisherKit,
        audioNetworkStatsUpdated stats: [OTPublisherKitAudioNetworkStats]
    ) {
        let statsArray = stats.map { stat -> [String: Any] in
            return [
                "connectionId": stat.connectionId,
                "subscriberId": stat.subscriberId,
                "audioPacketsLost": stat.audioPacketsLost,
                "audioBytesSent": stat.audioBytesSent,
                "audioPacketsSent": stat.audioPacketsSent,
                "timestamp": stat.timestamp,
            ]
        }

        if let jsonData = try? JSONSerialization.data(
            withJSONObject: statsArray
        ),
            let jsonString = String(data: jsonData, encoding: .utf8),
            let impl = impl
        {
            impl.strictUIViewContainer?.handleAudioNetworkStats(jsonString)
        }
    }

    func publisher(
        _ publisher: OTPublisherKit,
        videoNetworkStatsUpdated stats: [OTPublisherKitVideoNetworkStats]
    ) {
        let statsArray = stats.map { stat -> [String: Any] in
            return [
                "connectionId": stat.connectionId,
                "subscriberId": stat.subscriberId,
                "videoPacketsLost": stat.videoPacketsLost,
                "videoBytesSent": stat.videoBytesSent,
                "videoPacketsSent": stat.videoPacketsSent,
                "timestamp": stat.timestamp,
            ]
        }

        if let jsonData = try? JSONSerialization.data(
            withJSONObject: statsArray
        ),
            let jsonString = String(data: jsonData, encoding: .utf8),
            let impl = impl
        {
            impl.strictUIViewContainer?.handleVideoNetworkStats(jsonString)
        }
    }
}

private class PublisherRtcStatsDelegateHandler: NSObject,
    OTPublisherKitRtcStatsReportDelegate
{
    weak var impl: OTRNPublisherImpl?

    init(impl: OTRNPublisherImpl) {
        super.init()
        self.impl = impl
    }

    func publisher(
        _ publisher: OTPublisherKit,
        rtcStatsReport: [OTPublisherRtcStats]
    ) {
        let statsArray = rtcStatsReport.map { stat -> [String: Any] in
            return [
                "connectionId": stat.connectionId,
                "jsonArrayOfReports": stat.jsonArrayOfReports,
            ]
        }

        if let jsonData = try? JSONSerialization.data(
            withJSONObject: statsArray
        ),
            let jsonString = String(data: jsonData, encoding: .utf8),
            let impl = impl
        {
            impl.strictUIViewContainer?.handleRtcStatsReport(jsonString)
        }
    }
}
