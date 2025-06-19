import Foundation
import OpenTok
import React

@objc public class OpentokReactNativeImpl: NSObject {

    var ot: OpentokReactNative?
    var otSession: OTSession?
    fileprivate var sessionDelegateHandler: SessionDelegateHandler?

    @objc public init(ot: OpentokReactNative) {
        self.ot = ot
        super.init()
        OTRN.sharedState.opentokModule = ot
    }

    @objc public func initSession(
        _ apiKey: String, sessionId: String, sessionOptions: [String: Any]
    ) {
        let enableStereoOutput: Bool = Utils.sanitizeBooleanProperty(
            sessionOptions["enableStereoOutput"] as Any)
        if enableStereoOutput == true {
            let customAudioDevice = OTCustomAudioDriver()
            OTAudioDeviceManager.setAudioDevice(customAudioDevice)
        }
        let settings = OTSessionSettings()
        settings.connectionEventsSuppressed = Utils.sanitizeBooleanProperty(
            sessionOptions["connectionEventsSuppressed"] as Any)
        // Note: IceConfig is an additional property not supported at the moment. We need to add a sanitize function
        // to validate the input from settings.iceConfig.
        // settings.iceConfig = sessionOptions["iceConfig"];
        settings.proxyURL = Utils.sanitizeStringProperty(
            sessionOptions["proxyUrl"] as Any)
        settings.ipWhitelist = Utils.sanitizeBooleanProperty(
            sessionOptions["ipWhitelist"] as Any)
        settings.iceConfig = Utils.sanitizeIceServer(
            sessionOptions["customServers"] as Any,
            sessionOptions["transportPolicy"] as Any,
            sessionOptions["filterOutLanCandidates"] as Any,
            sessionOptions["includeServers"] as Any)
        settings.singlePeerConnection = Utils.sanitizeBooleanProperty(
            sessionOptions["enableSinglePeerConnection"] as Any)
        settings.sessionMigration = Utils.sanitizeBooleanProperty(
            sessionOptions["sessionMigration"] as Any)
        sessionDelegateHandler = SessionDelegateHandler(impl: self)
        otSession = OTSession(
            apiKey: apiKey, sessionId: sessionId,
            delegate: sessionDelegateHandler, settings: settings)
        OTRN.sharedState.sessions.updateValue(otSession!, forKey: sessionId)
    }

    @objc public func connect(
        _ sessionId: String,
        token: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        var error: OTError?
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject(
                "ERROR",
                "Error connecting to session. Could not find native session instance",
                nil)
            return
        }

        session.connect(withToken: token, error: &error)
        if let err = error {
            reject("ERROR", err.localizedDescription, err)
        } else {
            OTRN.sharedState.sessionConnectCallbacks[sessionId] = { _ in
                resolve(nil)
            }
        }
    }

    @objc public func disconnect(
        _ sessionId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        var error: OTError?
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject(
                "ERROR",
                "Error disconnecting from session. Could not find native session instance",
                nil)
            return
        }

        session.disconnect(&error)
        if let err = error {
            reject("ERROR", err.localizedDescription, err)
        } else {
            // Store resolve callback to be called after session fully disconnects
            OTRN.sharedState.sessionDisconnectCallbacks[sessionId] = { _ in
                resolve(nil)
            }
        }
    }

    @objc public func sendSignal(
        _ sessionId: String,
        signal: [String: String],
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        var error: OTError?
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject(
                "ERROR",
                "Error sending signal. Could not find native session instance",
                nil)
            return
        }

        if let connectionId = signal["to"] {
            let connection = OTRN.sharedState.connections[connectionId]
            session.signal(
                withType: signal["type"], string: signal["data"],
                connection: connection, error: &error)
        } else {
            session.signal(
                withType: signal["type"], string: signal["data"],
                connection: nil, error: &error)
        }

        if let err = error {
            reject("ERROR", err.localizedDescription, err)
        } else {
            resolve(nil)
        }
    }

    @objc public func setEncryptionSecret(
        _ sessionId: String,
        secret: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        var error: OTError?
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject(
                "ERROR",
                "Error setting encryption secret. Could not find native session instance.",
                nil)
            return
        }

        session.setEncryptionSecret(secret, error: &error)
        if let err = error {
            reject("ERROR", err.localizedDescription, nil)
        } else {
            resolve(nil)
        }
    }

    @objc public func reportIssue(
        _ sessionId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject(
                "ERROR",
                "Error reporting issue. Could not find native session instance.",
                nil)
            return
        }

        var issueId: NSString?
        session.reportIssue(&issueId)

        if let id = issueId {
            resolve(id as String)
        } else {
            reject("ERROR", "Failed to generate issue ID", nil)
        }
    }

    //@objc public func publish(_ publisherId: String,
    //                         resolve: @escaping RCTPromiseResolveBlock,
    //                         reject: @escaping RCTPromiseRejectBlock) -> Void {
    //    var error: OTError?
    //
    //    guard let publisher = OTRN.sharedState.publishers[publisherId] else {
    //        reject("ERROR", "Error publishing. Could not find native publisher instance", nil)
    //        return
    //    }
    //
    //    guard let otSession = otSession else {
    //        reject("ERROR", "Error connecting to session. Could not find native session instance", nil)
    //        return
    //    }
    //
    //    otSession.publish(publisher, error: &error)
    //
    //    if let err = error {
    //        reject("ERROR", err.localizedDescription, err)
    //    } else {
    //        resolve(nil)
    //    }
    //}

    @objc public func publish(_ publisherId: String) {
        var error: OTError?

        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            return
        }

        guard let otSession = otSession else {
            return
        }

        otSession.publish(publisher, error: &error)

        if let err = error {

        } else {

        }
    }

    @objc public func unpublish(_ publisherId: String) {
        var error: OTError?

        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            return
        }

        guard let otSession = otSession else {
            return
        }

        otSession.unpublish(publisher, error: &error)
        OTRN.sharedState.publishers.removeValue(forKey: publisherId)
    }

    @objc public func removeSubscriber(_ streamId: String) {
        var error: OTError?

        guard let otSession = otSession else {
            return
        }

        guard
            let subscriber = OTRN.sharedState.subscribers[streamId]
        else {
            return
        }

        otSession.unsubscribe(subscriber, error: &error)
        OTRN.sharedState.subscribers.removeValue(forKey: streamId)
    }

    @objc public func forceMuteAll(
        _ sessionId: String,
        excludedStreamIds: [String],
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject("event_failure", "Session ID not found", nil)
            return
        }
        var excludedStreams: [OTStream] = []
        for streamId in excludedStreamIds {
            guard
                let stream = OTRN.sharedState.subscriberStreams[streamId]
                    ?? OTRN.sharedState.publisherStreams[streamId]
            else {
                continue  // Ignore bogus stream IDs
            }
            excludedStreams.append(stream)
        }
        var error: OTError?
        session.forceMuteAll(excludedStreams, error: &error)
        if let error = error {
            reject("event_failure", error.localizedDescription, nil)
            return
        }
        resolve(true)
    }

    @objc public func forceMuteStream(
        _ sessionId: String,
        streamId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject("event_failure", "Session ID not found", nil)
            return
        }
        guard
            let stream = OTRN.sharedState.subscriberStreams[streamId]
                ?? OTRN.sharedState.publisherStreams[streamId]
        else {
            reject("ERROR", "Stream ID not found", nil)
            return
        }
        var error: OTError?
        session.forceMuteStream(stream, error: &error)
        if let error = error {
            reject("event_failure", error.localizedDescription, nil)
            return
        }
        resolve(true)
    }

    @objc public func disableForceMute(
        _ sessionId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject("event_failure", "Session not found.", nil)
            return
        }
        var error: OTError?
        session.disableForceMute(&error)
        if let error = error {
            reject("event_failure", error.localizedDescription, nil)
            return
        }
        resolve(true)
    }

    @objc public func getPublisherRtcStatsReport(_ publisherId: String) {
        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            return
        }
        publisher.getRtcStatsReport()
    }

    @objc public func getSubscriberRtcStatsReport() -> Void {
        var error: OTError?
        for subscriber in OTRN.sharedState.subscribers {
            if let streamId = subscriber.value.stream?.streamId,
               OTRN.sharedState.subscriberStreams[streamId] != nil {
                subscriber.value.getRtcStatsReport(&error)
                if let error = error {
                    print("getSubscriberRtcStatsReport event_failure \(error.localizedDescription)")
                }
            }
        }
    }

    @objc public func setAudioTransformers(_ publisherId: String, transformers: NSArray) -> Void {
        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            print("ERROR: Could not find publisher with ID \(publisherId)")
            return
        }
        
        var nativeTransformers: [OTAudioTransformer] = []

        for case let transformer as [String: Any] in transformers {
            guard let transformerName = transformer["name"] as? String else {
                print("ERROR: Invalid transformer format. Each transformer must have a 'name' key")
                return
            }
            
            let transformerProperties = transformer["properties"] as? String ?? ""
            
            guard let nativeTransformer = OTAudioTransformer(
                name: transformerName,
                properties: transformerProperties
            ) else {
                print("ERROR: Failed to create audio transformer with name: \(transformerName)")
                return
            }
            
            nativeTransformers.append(nativeTransformer)
        }
        
        publisher.audioTransformers = nativeTransformers
    }

    @objc public func setVideoTransformers(_ publisherId: String, transformers: NSArray) -> Void {
        guard let publisher = OTRN.sharedState.publishers[publisherId] else {
            print("ERROR: Could not find publisher with ID \(publisherId)")
            return
        }
        
        var nativeTransformers: [OTVideoTransformer] = []

        for case let transformer as [String: Any] in transformers {
            guard let transformerName = transformer["name"] as? String else {
                print("ERROR: Invalid transformer format. Each transformer must have a 'name' key")
                return
            }
            
            let transformerProperties = transformer["properties"] as? String ?? ""
            
            guard let nativeTransformer = OTVideoTransformer(
                name: transformerName,
                properties: transformerProperties
            ) else {
                print("ERROR: Failed to create video transformer with name: \(transformerName)")
                return
            }
            
            nativeTransformers.append(nativeTransformer)
        }
        
        publisher.videoTransformers = nativeTransformers
    }
}

class DebugAlertHelper {
    class func showDebugAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Debug", message: message, preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(title: "OK", style: .default, handler: nil))
            if let rootViewController = UIApplication.shared.delegate?.window??
                .rootViewController
            {
                rootViewController.present(
                    alert, animated: true, completion: nil)
            }
        }
    }
}

private class SessionDelegateHandler: NSObject, OTSessionDelegate {
    weak var impl: OpentokReactNativeImpl?

    init(impl: OpentokReactNativeImpl) {
        self.impl = impl
        super.init()
    }

    public func sessionDidConnect(_ session: OTSession) {
        let sessionInfo = EventUtils.prepareJSSessionEventData(session);
        impl?.ot?.emit(onSessionConnected: sessionInfo)
    }

    public func session(_ session: OTSession, didFailWithError error: OTError) {
        let errorInfo: [String: Any] = EventUtils.prepareJSErrorEventData(error)
        impl?.ot?.emit(onSessionError: errorInfo)
    }

    public func session(_ session: OTSession, streamCreated stream: OTStream) {
        OTRN.sharedState.subscriberStreams.updateValue(stream, forKey: stream.streamId)
        let streamInfo: [String: Any] = EventUtils.prepareJSStreamEventData(stream)
        impl?.ot?.emit(onStreamCreated: streamInfo)
        Utils.setStreamObservers(stream: stream, isPublisherStream: false)
    }

    public func session(_ session: OTSession, streamDestroyed stream: OTStream)
    {
        let streamInfo: [String: Any] = EventUtils.prepareJSStreamEventData(
            stream)
        OTRN.sharedState.subscriberStreams.removeValue(forKey: stream.streamId)
        impl?.ot?.emit(onStreamDestroyed: streamInfo)
    }

    public func sessionDidDisconnect(_ session: OTSession) {
        let sessionInfo = EventUtils.prepareJSSessionEventData(session);
        impl?.ot?.emit(onSessionDisconnected: sessionInfo)

        // Cleanup session state
        session.delegate = nil
        OTRN.sharedState.sessions.removeValue(forKey: session.sessionId)
    }


    public func session(
        _ session: OTSession, connectionCreated connection: OTConnection
    ) {
        OTRN.sharedState.connections.updateValue(
            connection, forKey: connection.connectionId)
        let connectionInfo = EventUtils.prepareJSSessionEventData(session)
        impl?.ot?.emit(onConnectionCreated: connectionInfo)
    }

    public func session(
        _ session: OTSession, connectionDestroyed connection: OTConnection
    ) {
        OTRN.sharedState.connections.removeValue(
            forKey: connection.connectionId)
        let connectionInfo = EventUtils.prepareJSSessionEventData(session)
        impl?.ot?.emit(onConnectionDestroyed: connectionInfo)
    }
    public func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
        var signalData: Dictionary<String, Any> = [:];
        signalData["type"] = type;
        signalData["data"] = string;
        signalData["connectionId"] = connection?.connectionId;
        signalData["sessionId"] = session.sessionId;
        impl?.ot?.emit(onSignalReceived:  signalData)
    }
    public func session(_ session: OTSession, info muteForced: OTMuteForcedInfo)
    {
        var muteForcedInfo: [String: Any] = [:]
        muteForcedInfo["active"] = muteForced.active
        impl?.ot?.emit(onMuteForced: muteForcedInfo)
    }
    public func session(
        _ session: OTSession, archiveStartedWithId archiveId: String,
        name: String?
    ) {
        let archiveInfo: [String: Any] = [
            "archiveId": archiveId,
            "name": name ?? "",
            "sessionId": session.sessionId,
        ]
        impl?.ot?.emit(onArchiveStarted: archiveInfo)
    }

    public func session(
        _ session: OTSession, archiveStoppedWithId archiveId: String
    ) {
        let archiveInfo: [String: Any] = [
            "archiveId": archiveId,
            "name": "",  // Name is not available in stop event
            "sessionId": session.sessionId,
        ]
        impl?.ot?.emit(onArchiveStopped: archiveInfo)
    }
    public func sessionDidBeginReconnecting(_ session: OTSession) {
        let sessionInfo = EventUtils.prepareJSSessionEventData(session)
        impl?.ot?.emit(onSessionReconnecting: sessionInfo)
    }

    public func sessionDidReconnect(_ session: OTSession) {
        let sessionInfo = EventUtils.prepareJSSessionEventData(session)
        impl?.ot?.emit(onSessionReconnected: sessionInfo)
    }
}

