//
//  OTPublisherView.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/17/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation

@objc(OTPublisherView)
class OTPublisherView : UIView {
  @objc var publisherId: NSString?
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func layoutSubviews() {
    guard let otrnPublisher = OTRN.sharedState.otrnPublishers[publisherId! as String] else { return }
    guard let publisherView = otrnPublisher.publisher?.view else { return }
    publisherView.frame = self.frame
    addSubview(publisherView)
  }
}

