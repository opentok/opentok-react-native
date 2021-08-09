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
  @objc var publisherId: NSString? {
    didSet {
      if let publisherView = OTRN.sharedState.publishers[publisherId! as String]?.view {
        publisherView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(publisherView)
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

