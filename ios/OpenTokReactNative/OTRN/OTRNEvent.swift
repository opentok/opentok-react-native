//
//  OTRNEvent.swift
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 2/26/19.
//  Copyright © 2019 TokBox Inc. All rights reserved.
//

import Foundation

@objc class OTRNEvent: NSObject {
    var data: Any?
    @objc dynamic var event: String = ""
    
    func setEvent(event: String) {
        self.event = event
    }
    
    func setData(data: Any) {
        self.data = data
    }
}
