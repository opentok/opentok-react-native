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
  var session: OTSession?
  var subscriberStreams = [String: OTStream]()
  var subscribers = [String: OTSubscriber]()
  var publishers = [String: OTPublisher]()
  var isPublishing = [String: Bool]()
  var streamObservers = [String: [NSKeyValueObservation]]()
  override init() {
    super.init()
  }
}
