//
//  OTRNEventEmitter.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 2/26/19.
//  Copyright © 2019 TokBox Inc. All rights reserved.
//

import Foundation
@objc(OTRNEventEmitter)
class OTRNEventEmitter: RCTEventEmitter {

    let sessionPreface: String = "session:"
    let publisherPreface: String = "publisher:"
    let subscriberPreface: String = "subscriber:"
    
    override func supportedEvents() -> [String]! {
        return ["\(sessionPreface)streamCreated", "\(sessionPreface)streamDestroyed", "\(sessionPreface)sessionDidConnect", "\(sessionPreface)sessionDidDisconnect", "\(sessionPreface)connectionCreated", "\(sessionPreface)connectionDestroyed", "\(sessionPreface)didFailWithError", "\(publisherPreface)streamCreated", "\(sessionPreface)signal", "\(publisherPreface)streamDestroyed", "\(publisherPreface)didFailWithError", "\(publisherPreface)audioLevelUpdated", "\(subscriberPreface)subscriberDidConnect", "\(subscriberPreface)subscriberDidDisconnect", "\(subscriberPreface)didFailWithError", "\(subscriberPreface)videoNetworkStatsUpdated", "\(subscriberPreface)audioNetworkStatsUpdated", "\(subscriberPreface)audioLevelUpdated", "\(subscriberPreface)subscriberVideoEnabled", "\(subscriberPreface)subscriberVideoDisabled", "\(subscriberPreface)subscriberVideoDisableWarning", "\(subscriberPreface)subscriberVideoDisableWarningLifted", "\(subscriberPreface)subscriberVideoDataReceived", "\(sessionPreface)archiveStartedWithId", "\(sessionPreface)archiveStoppedWithId", "\(sessionPreface)sessionDidBeginReconnecting", "\(sessionPreface)sessionDidReconnect", "\(sessionPreface)streamPropertyChanged", "\(subscriberPreface)subscriberDidReconnect"];
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
}
