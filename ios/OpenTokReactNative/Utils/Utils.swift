//
//  Utils.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 11/3/18.
//  Copyright © 2018 TokBox Inc. All rights reserved.
//

import Foundation

class Utils {
    static func sanitizeCameraResolution(_ resolution: Any) -> OTCameraCaptureResolution {
        guard let cameraResolution = resolution as? String else { return .medium };
        switch cameraResolution {
        case "HIGH":
            return .high;
        case "LOW":
            return .low;
        default:
            return .medium;
        }
    }
    
    static func sanitizeFrameRate(_ frameRate: Any) -> OTCameraCaptureFrameRate {
        guard let cameraFrameRate = frameRate as? Int else { return OTCameraCaptureFrameRate(rawValue: 30)!; }
        return OTCameraCaptureFrameRate(rawValue: cameraFrameRate)!;
    }
    
    static func sanitizeSessionSettings(_ settings: Dictionary<String, Any>) -> OTSessionSettings {
        let sessionSettings = OTSessionSettings()
        sessionSettings.connectionEventsSuppressed = self.sanitizeBooleanProperty(property: settings["connectionEventsSuppressed"] as Any)
        return sessionSettings
    }
    
    static func sanitizeBooleanProperty(_ property: Any) -> Bool {
        guard let prop = property as? Bool else { return true; }
        return prop;
    }
    
    static func convertOTSubscriberVideoEventReasonToString(_ reason: OTSubscriberVideoEventReason) -> String {
        switch reason {
        case OTSubscriberVideoEventReason.publisherPropertyChanged:
            return "PublisherPropertyChanged"
        case OTSubscriberVideoEventReason.subscriberPropertyChanged:
            return "SubscriberPropertyChanged"
        case OTSubscriberVideoEventReason.qualityChanged:
            return "QualityChanged"
        }
    }
    
    static func dispatchCallbackWithError(callback: RCTResponseSenderBlock, error: OTError) {
        let errorEventData = EventUtils.prepareJSErrorEventData(error)
        callback([errorEventData])
    }
    
   static func printLogs(_ message: String) {
        if (OTRN.sharedState.logLevel) {
            print(message)
        }
    }
}
