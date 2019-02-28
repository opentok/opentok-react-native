//
//  OTPublisher.m
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/17/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTPublisher.h"
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(OTPublisherSwift, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(publisherId, NSString)
@end

