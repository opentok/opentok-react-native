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

@interface RCT_EXTERN_MODULE(OTRNService, RCTEventEmitter)

RCT_EXTERN_METHOD(initSession:
                  (NSString*)apiKey
                  sessionId:(NSString*)sessionId
                  properties:(NSDictionary*)properties)
RCT_EXTERN_METHOD(connect:
                  (NSString*)sessionId
                  token:(NSString*)token
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(initPublisher:
                  (NSString*)publisherId
                  properties:(NSDictionary*)properties
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(publish:
                  (NSString*)sessionId
                  publisherId:(NSString*)publisherId
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(initSubscriber:
                  (NSString*)streamId
                  properties:(NSDictionary*)properties
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(subscribe:
                  (NSString*)sessionId
                  streamId:(NSString*)streamId
                  properties:(NSDictionary*)properties
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(removeSubscriber:
                  (NSString*)streamId
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(disconnectSession:
                  (NSString*)sessionId
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(publishAudio:
                  (NSString*)publisherId
                  pubAudio:(BOOL)pubAudio)
RCT_EXTERN_METHOD(publishVideo:
                  (NSString*)publisherId
                  pubVideo:(BOOL)pubVideo)
RCT_EXTERN_METHOD(subscribeToAudio:
                  (NSString*)streamId
                  subAudio:(BOOL)subAudio)
RCT_EXTERN_METHOD(subscribeToVideo:
                  (NSString*)streamId
                  subVideo:(BOOL)subVideo)
RCT_EXTERN_METHOD(changeCameraPosition:
                  (NSString*)publisherId
                  cameraPosition:(NSString*)cameraPosition)
RCT_EXTERN_METHOD(setSessionEvents:
                  (NSString*)sessionId
                  events:(NSArray*)events)
RCT_EXTERN_METHOD(removeSessionEvents:
                  (NSString*)sessionId
                  events:(NSArray*)events)
RCT_EXTERN_METHOD(setPublisherEvents:
                  (NSString*)publisherId
                  events:(NSArray*)events)
RCT_EXTERN_METHOD(removePublisherEvents:
                  (NSString*)publisherId
                  events:(NSArray*)events)
RCT_EXTERN_METHOD(setSubscriberEvents:
                  (NSString*)streamId
                  events:(NSArray*)events)
RCT_EXTERN_METHOD(removeSubscriberEvents:
                  (NSString*)streamId
                  events:(NSArray*)events)
RCT_EXTERN_METHOD(sendSignal:
                  (NSString*)sessionId
                  signal:(NSDictionary*)signal
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(destroyPublisher:
                  (NSString*)sessionId
                  publisherId:(NSString*)publisherId
                  callback:(RCTResponseSenderBlock)callback)
RCT_EXTERN_METHOD(getSessionInfo:
                  (NSString*)sessionId
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(enableLogs:
                  (BOOL)logLevel)
@end

@interface RCT_EXTERN_MODULE(OTRNEventEmitter, RCTEventEmitter)
@end
