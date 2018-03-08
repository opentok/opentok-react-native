//
//  OTRN.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/16/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation
import OpenTok

class OTRN : NSObject {
  static let sharedState = OTRN()
  var session: OTSession?
  var publisher: OTPublisher?
  var subscriberStreams = [String: OTStream]()
  var subscribers = [String: OTSubscriber]()
  override init() {
    super.init()
  }
}

