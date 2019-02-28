//
//  OTSubscriberManager.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/18/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation

@objc(OTSubscriberSwift)
class OTSubscriberManager: RCTViewManager {
  override func view() -> UIView {
    return OTSubscriberView();
  }
  
  override static func requiresMainQueueSetup() -> Bool {
    return true;
  }
}

