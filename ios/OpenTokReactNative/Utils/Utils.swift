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
    
    static func sanitizeBooleanProperty(_ property: Any) -> Bool {
        guard let prop = property as? Bool else { return true; }
        return prop;
    }
    
    static func getPublisherId(_ publisher: OTPublisher) -> String {
        let publisherIds = OTRN.sharedState.publishers.filter {$0.value == publisher}
        guard let publisherId = publisherIds.first else { return ""; }
        return publisherId.key;
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
}
