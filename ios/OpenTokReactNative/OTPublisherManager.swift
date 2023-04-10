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

  /*
  @objc func getRtcStatsReport(publisherId: String, callback: RCTResponseSenderBlock) -> Void {
      var error: OTError?
      guard let publisher = OTRN.sharedState.publishers[publisherId] else {
          let errorInfo = EventUtils.createErrorMessage("getRtcStatsReport error. Could not find native publisher instance")
          callback([errorInfo])
          return
      }
      publisher.getRtcStatsReport()
      callback([NSNull()])
  }
  */
}

