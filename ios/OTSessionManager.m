//
//  OTSessionManager.m
//  OpenTokReactNative
//
//  Created by Manik Sachdeva on 1/12/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTBridgeMethod.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(OTSessionManager, RCTEventEmitter)

RCT_EXTERN_METHOD(initSession:
                  (NSString*)apiKey
                  sessionId:(NSString*)sessionId)
RCT_EXTERN_METHOD(connect:
                  (NSString*)token
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(initPublisher:
                  (NSDictionary*)properties
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(publish:
                  (RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(subscribeToStream:
                  (NSString*)streamId
                  properties:(NSDictionary*)properties
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(removeSubscriber:
                  (NSString*)streamId
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(disconnectSession:
                  (RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(publishAudio:
                  (BOOL)pubAudio)
RCT_EXTERN_METHOD(publishVideo:
                  (BOOL)pubVideo)
RCT_EXTERN_METHOD(setNativeEvents:
                  (NSArray*)events)
RCT_EXTERN_METHOD(removeNativeEvents:
                  (NSArray*)events)
RCT_EXTERN_METHOD(sendSignal:
                  (NSDictionary*)properties
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(destroyPublisher:
                  (RCTResponseSenderBlock)callback)
RCT_EXTERN_METHOD(setJSComponentEvents:
                  (NSArray*)events)
RCT_EXTERN_METHOD(removeJSComponentEvents:
                  (NSArray*)events)
RCT_EXTERN_METHOD(getSessionInfo:
                  (RCTResponseSenderBlock*)callback)
@end

