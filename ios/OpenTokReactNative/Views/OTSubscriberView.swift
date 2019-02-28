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
  @objc var streamId: NSString?
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    guard let otrnSubscriber = OTRN.sharedState.otrnSubscribers[streamId! as String] else { return }
    guard let subscriberView = otrnSubscriber.subscriber?.view else { return }
    subscriberView.frame = self.frame
    addSubview(subscriberView)
  }
}

