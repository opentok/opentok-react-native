import Foundation
import OpenTok
import React

@objc public class OpentokReactNativeImpl: NSObject {
  
    var ot: OpentokReactNative?
    var otSession: OTSession?
    fileprivate var sessionDelegateHandler: SessionDelegateHandler?

    @objc public init(ot: OpentokReactNative) {
        self.ot = ot
    }

 @objc public func initSession(_ apiKey: String, sessionId: String, sessionOptions: Dictionary<String, Any>) -> Void {
        let enableStereoOutput: Bool = Utils.sanitizeBooleanProperty(sessionOptions["enableStereoOutput"] as Any);
        if enableStereoOutput == true {
            let customAudioDevice = OTCustomAudioDriver()
            OTAudioDeviceManager.setAudioDevice(customAudioDevice)
        }
        let settings = OTSessionSettings();
        settings.connectionEventsSuppressed = Utils.sanitizeBooleanProperty(sessionOptions["connectionEventsSuppressed"] as Any);
        // Note: IceConfig is an additional property not supported at the moment. We need to add a sanitize function
        // to validate the input from settings.iceConfig.
        // settings.iceConfig = sessionOptions["iceConfig"];
        settings.proxyURL = Utils.sanitizeStringProperty(sessionOptions["proxyUrl"] as Any);
        settings.ipWhitelist = Utils.sanitizeBooleanProperty(sessionOptions["ipWhitelist"] as Any);
        settings.iceConfig = Utils.sanitizeIceServer(sessionOptions["customServers"] as Any, sessionOptions["transportPolicy"] as Any, sessionOptions["includeServers"] as Any);
        settings.singlePeerConnection = Utils.sanitizeBooleanProperty(sessionOptions["enableSinglePeerConnection"] as Any);
        sessionDelegateHandler = SessionDelegateHandler(impl: self)
        OTRN.sharedState.sessions.updateValue(OTSession(apiKey: apiKey, sessionId: sessionId, delegate: sessionDelegateHandler, settings: settings)!, forKey: sessionId);
    }



@objc public func connect(_ sessionId: String, 
                         token: String, 
                         resolve: @escaping RCTPromiseResolveBlock,
                         reject: @escaping RCTPromiseRejectBlock) -> Void {
    var error: OTError?
    guard let session = OTRN.sharedState.sessions[sessionId] else {
        reject("ERROR", "Error connecting to session. Could not find native session instance", nil)
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

@objc public func disconnect(_ sessionId: String,
                           resolve: @escaping RCTPromiseResolveBlock,
                           reject: @escaping RCTPromiseRejectBlock) -> Void {
    var error: OTError?
    guard let session = OTRN.sharedState.sessions[sessionId] else {
        reject("ERROR", "Error disconnecting from session. Could not find native session instance", nil)
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

@objc public func sendSignal(_ sessionId: String, 
                            signal: Dictionary<String, String>,
                            resolve: @escaping RCTPromiseResolveBlock,
                            reject: @escaping RCTPromiseRejectBlock) -> Void {
    var error: OTError?
    guard let session = OTRN.sharedState.sessions[sessionId] else {
        reject("ERROR", "Error sending signal. Could not find native session instance", nil)
        return
    }
    
    if let connectionId = signal["to"] {
        let connection = OTRN.sharedState.connections[connectionId]
        session.signal(withType: signal["type"], string: signal["data"], connection: connection, error: &error)
    } else {
        session.signal(withType: signal["type"], string: signal["data"], connection: nil, error: &error)
    }
    
    if let err = error {
        reject("ERROR", err.localizedDescription, err)
    } else {
        resolve(nil)
    }
}


@objc public func setEncryptionSecret(_ sessionId: String, 
                                         secret: String, 
                                         resolve: @escaping RCTPromiseResolveBlock,
                                         reject: @escaping RCTPromiseRejectBlock) {
        var error: OTError?
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject("ERROR", "Error setting encryption secret. Could not find native session instance.", nil)
            return
        }
        
        session.setEncryptionSecret(secret, error: &error)
        if let err = error {
            reject("ERROR", err.localizedDescription, nil)
        } else {
            resolve(nil)
        }
    }

@objc public func reportIssue(_ sessionId: String,
                                 resolve: @escaping RCTPromiseResolveBlock,
                                 reject: @escaping RCTPromiseRejectBlock) {
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject("ERROR", "Error reporting issue. Could not find native session instance.", nil)
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

@objc public func forceMuteAll(_ sessionId: String,
                                  excludedStreamIds: Array<String>,
                                  resolve: @escaping RCTPromiseResolveBlock,
                                  reject: @escaping RCTPromiseRejectBlock) {
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject("event_failure", "Session ID not found", nil)
            return
        }
        var excludedStreams: [OTStream] = []
        for streamId in excludedStreamIds {
            guard let stream = OTRN.sharedState.subscriberStreams[streamId] ?? OTRN.sharedState.publisherStreams[streamId] else {
                continue // Ignore bogus stream IDs
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
    
    @objc public func forceMuteStream(_ sessionId: String,
                                     streamId: String,
                                     resolve: @escaping RCTPromiseResolveBlock,
                                     reject: @escaping RCTPromiseRejectBlock) {
        guard let session = OTRN.sharedState.sessions[sessionId] else {
            reject("event_failure", "Session ID not found", nil)
            return
        }
        guard let stream = OTRN.sharedState.subscriberStreams[streamId] else {
            reject("event_failure", "Stream ID not found", nil)
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
    
    @objc public func disableForceMute(_ sessionId: String,
                                      resolve: @escaping RCTPromiseResolveBlock,
                                      reject: @escaping RCTPromiseRejectBlock) {
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
}

class DebugAlertHelper {
    class func showDebugAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Debug", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
                rootViewController.present(alert, animated: true, completion: nil)
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
        // Handle callback from shared state
        guard let callback = OTRN.sharedState.sessionConnectCallbacks[session.sessionId] else { return }
        callback([NSNull()])
        
        // Prepare and emit event
        let eventDict: [AnyHashable: Any] = [
            "sessionId": session.sessionId,
            "connectionId": session.connection?.connectionId ?? ""
        ]
        impl?.ot?.emit(onSessionConnected: eventDict)
    }

    public func session(_ session: OTSession, didFailWithError error: OTError) {
        let errorInfo: Dictionary<String, Any> = EventUtils.prepareJSErrorEventData(error);
        impl?.ot?.emit(onSessionError: errorInfo)
    }
        


    public func session(_ session: OTSession, streamCreated stream: OTStream) {
        OTRN.sharedState.subscriberStreams.updateValue(stream, forKey: stream.streamId)
        let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream)
        impl?.ot?.emit(onStreamCreated: streamInfo)
        setStreamObservers(stream: stream, isPublisherStream: false)
    }

    public func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream)
        impl?.ot?.emit(onStreamDestroyed: streamInfo)
        OTRN.sharedState.subscriberStreams.removeValue(forKey: stream.streamId)
    }

    public func sessionDidDisconnect(_ session: OTSession) {
        // Emit event
        let eventDict: [String: Any] = [
            "sessionId": session.sessionId,
            "connectionId": session.connection?.connectionId ?? ""
        ]
        impl?.ot?.emit(onSessionDisconnected: eventDict)
        
        // Cleanup session state
        session.delegate = nil
        OTRN.sharedState.sessions.removeValue(forKey: session.sessionId)
        OTRN.sharedState.sessionConnectCallbacks.removeValue(forKey: session.sessionId)
    }
    func setStreamObservers(stream: OTStream, isPublisherStream: Bool) {
        let streamId = stream.streamId
        
        // Video dimensions observer
        let dimensionsObserver = stream.observe(\.videoDimensions, options: [.old, .new]) { stream, change in
            guard let oldDimensions = change.oldValue,
                  let newDimensions = change.newValue,
                  oldDimensions != newDimensions else { return }
            
            let oldValue = [
                "width": oldDimensions.width,
                "height": oldDimensions.height
            ]
            let newValue = [
                "width": newDimensions.width,
                "height": newDimensions.height
            ]
            
            self.checkAndEmitStreamPropertyChangeEvent(streamId,
                                                     changedProperty: "videoDimensions",
                                                     oldValue: oldValue,
                                                     newValue: newValue,
                                                     isPublisherStream: isPublisherStream)
        }

        // Audio observer
        let audioObserver = stream.observe(\.hasAudio, options: [.old, .new]) { stream, change in
            guard let oldValue = change.oldValue,
                  let newValue = change.newValue,
                  oldValue != newValue else { return }
            
            self.checkAndEmitStreamPropertyChangeEvent(streamId,
                                                     changedProperty: "hasAudio",
                                                     oldValue: oldValue,
                                                     newValue: newValue,
                                                     isPublisherStream: isPublisherStream)
        }
        
        // Video observer
        let videoObserver = stream.observe(\.hasVideo, options: [.old, .new]) { stream, change in
            guard let oldValue = change.oldValue,
                  let newValue = change.newValue,
                  oldValue != newValue else { return }
            
            self.checkAndEmitStreamPropertyChangeEvent(streamId,
                                                     changedProperty: "hasVideo",
                                                     oldValue: oldValue,
                                                     newValue: newValue,
                                                     isPublisherStream: isPublisherStream)
        }

        // Captions observer
        let captionsObserver = stream.observe(\.hasCaptions, options: [.old, .new]) { stream, change in
            guard let oldValue = change.oldValue,
                  let newValue = change.newValue,
                  oldValue != newValue else { return }
            
            self.checkAndEmitStreamPropertyChangeEvent(streamId,
                                                     changedProperty: "hasCaptions",
                                                     oldValue: oldValue,
                                                     newValue: newValue,
                                                     isPublisherStream: isPublisherStream)
        }
        
        // Store all observers
        OTRN.sharedState.streamObservers.updateValue([dimensionsObserver, audioObserver, videoObserver, captionsObserver], forKey: streamId)
    }
    func checkAndEmitStreamPropertyChangeEvent(_ streamId: String, changedProperty: String, oldValue: Any, newValue: Any, isPublisherStream: Bool) {
        guard let stream = isPublisherStream ? OTRN.sharedState.publisherStreams[streamId] : OTRN.sharedState.subscriberStreams[streamId] else { return }
        let streamInfo: Dictionary<String, Any> = EventUtils.prepareJSStreamEventData(stream)
        let eventData: Dictionary<String, Any> = EventUtils.prepareStreamPropertyChangedEventData(changedProperty, oldValue: oldValue, newValue: newValue, stream: streamInfo)
        impl?.ot?.emit(onStreamPropertyChanged: eventData)
    }
    public func session(_ session: OTSession, connectionCreated connection: OTConnection) {
        OTRN.sharedState.connections.updateValue(connection, forKey: connection.connectionId)
        var connectionInfo = EventUtils.prepareJSConnectionEventData(connection)
        connectionInfo["sessionId"] = session.sessionId
        impl?.ot?.emit(onConnectionCreated: connectionInfo)
    }
    
    public func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
        OTRN.sharedState.connections.removeValue(forKey: connection.connectionId)
        var connectionInfo = EventUtils.prepareJSConnectionEventData(connection)
        connectionInfo["sessionId"] = session.sessionId
        impl?.ot?.emit(onConnectionDestroyed: connectionInfo)
    }
    public func session(_ session: OTSession, info muteForced: OTMuteForcedInfo) {
        var muteForcedInfo: Dictionary<String, Any> = [:];
        muteForcedInfo["active"] = muteForced.active;
        impl?.ot?.emit(onMuteForced: muteForcedInfo)
    }
    public func session(_ session: OTSession, archiveStartedWithId archiveId: String, name: String?) {
        let archiveInfo: [String: Any] = [
            "archiveId": archiveId,
            "name": name ?? "",
            "sessionId": session.sessionId
        ]
        impl?.ot?.emit(onArchiveStarted: archiveInfo)
    }
    
    public func session(_ session: OTSession, archiveStoppedWithId archiveId: String) {
        let archiveInfo: [String: Any] = [
            "archiveId": archiveId,
            "name": "",  // Name is not available in stop event
            "sessionId": session.sessionId
        ]
        impl?.ot?.emit(onArchiveStopped: archiveInfo)
    }
    public func sessionDidBeginReconnecting(_ session: OTSession) {
        let sessionInfo = EventUtils.prepareJSSessionEventData(session)
        impl?.ot?.emit(onSessionDidBeginReconnecting: sessionInfo)
    }
    
    public func sessionDidReconnect(_ session: OTSession) {
        let sessionInfo = EventUtils.prepareJSSessionEventData(session)
        impl?.ot?.emit(onSessionDidReconnect: sessionInfo)
    }
}
