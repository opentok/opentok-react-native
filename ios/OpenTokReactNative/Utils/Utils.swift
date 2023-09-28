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
        case "HIGH_1080P":
            return .high1080p;
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
    
    static func sanitizePreferredFrameRate(_ frameRate: Any) -> Float {
        guard let sanitizedFrameRate = frameRate as? Float else { return Float.greatestFiniteMagnitude; }
        return sanitizedFrameRate;
    }
    
    static func sanitizePreferredResolution(_ resolution: Any) -> CGSize {
        guard let preferredRes = resolution as? Dictionary<String, Any> else { return CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude) };
        return CGSize(width: preferredRes["width"] as! CGFloat, height: preferredRes["height"] as! CGFloat);
    }
    
    static func sanitizeBooleanProperty(_ property: Any) -> Bool {
        guard let prop = property as? Bool else { return true; }
        return prop;
    }

    static func sanitizeStringProperty(_ property: Any) -> String {
        guard let prop = property as? String else { return ""; }
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
        case OTSubscriberVideoEventReason.codecNotSupported:
            return "CodecNotSupported"
        }
    }
    
    static func sanitizeIncludeServer(_ value: Any)  -> OTSessionICEIncludeServers {
        var includeServers = OTSessionICEIncludeServers.all;
        if let includeServer = value as? String, includeServer == "custom" {
            includeServers = OTSessionICEIncludeServers.custom;
        }
        return includeServers;
    }
    
    static func sanitizeTransportPolicy(_ value: Any)  -> OTSessionICETransportPolicy {
        var transportPolicy = OTSessionICETransportPolicy.all;
        if let policy = value as? String, policy == "relay" {
            transportPolicy = OTSessionICETransportPolicy.relay;
        }
        return transportPolicy;
    }
    
    static func sanitiseServerList(_ serverList: Any) -> [(urls: [String], userName: String, credential: String)] {
        var iceServerList: [([String], String, String)] = []
        
        if let serverList = serverList as? [[String: Any]] {
            for server in serverList {
                if let urls = server["urls"] as? [String], let username = server["username"] as? String, let credential = server["credential"] as? String {
                    iceServerList.append((urls, username, credential))
                }
            }
        }
        return iceServerList
    }
    
    static func sanitizeIceServer(_ serverList: Any, _ transportPolicy: Any, _ includeServer: Any) -> OTSessionICEConfig {
        let myICEServerConfiguration: OTSessionICEConfig = OTSessionICEConfig();
        myICEServerConfiguration.includeServers = Utils.sanitizeIncludeServer(includeServer);
        myICEServerConfiguration.transportPolicy = Utils.sanitizeTransportPolicy(transportPolicy);
        let serverList = Utils.sanitiseServerList(serverList);
        for server in serverList {
            for url in server.urls {
                myICEServerConfiguration.addICEServer(withURL: url, userName: server.userName, credential: server.credential, error: nil);
            }
        }
        return myICEServerConfiguration;
    }
    
    static func convertVideoContentHint(_ videoContentHint: Any) -> OTVideoContentHint {
        guard let contentHint = videoContentHint as? String else { return OTVideoContentHint.none };
        switch contentHint {
            case "motion":
                return OTVideoContentHint.motion
            case "detail":
                return OTVideoContentHint.detail
            case "text":
                return OTVideoContentHint.text
            default:
                return OTVideoContentHint.none
        }
    }
}
