//
//  OTSubscriberView.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/18/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation

@objc(OTSubscriberView)
class OTSubscriberView: UIView {
  var streamId: NSString?
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    if let subscriberView = OTRN.sharedState.subscribers[streamId! as String]?.view {
      subscriberView.frame = self.bounds
      addSubview(subscriberView)
    }
  }
}

