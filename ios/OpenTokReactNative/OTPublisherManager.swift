//
//  OTPublisher.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/17/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation

@objc(OTPublisherSwift)
class OTPublisherManager: RCTViewManager {
  override func view() -> UIView {
    return OTPublisherView();
  }
    
  override static func requiresMainQueueSetup() -> Bool {
    return true;
  }
}

