//
//  OTSubscriber.m
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/18/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTSubscriber.h"
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(OTSubscriberSwift, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(streamId, NSString)
@end

