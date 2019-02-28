//
//  OTRN.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/16/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation

class OTRN : NSObject {
  static let sharedState = OTRN()
    var subscriberStreams = [String: OTStream]()
    var otrnPublishers = [String: OTRNPublisher]()
    var otrnSessions = [String: OTRNSession]()
    var otrnSubscribers = [String: OTRNSubscriber]()
    var logLevel: Bool = false
  override init() {
    super.init()
  }
}
