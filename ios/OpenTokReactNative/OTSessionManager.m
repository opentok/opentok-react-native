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
                  sessionId:(NSString*)sessionId
                  sessionOptions:(NSDictionary*)sessionOptions)
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
RCT_EXTERN_METHOD(subscribeToStream:
                  (NSString*)streamId
                  sessionId:
                  (NSString*)sessionId
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
RCT_EXTERN_METHOD(publishCaptions:
                  (NSString*)publisherId
                  pubCaptions:(BOOL)publishCaptions)
RCT_EXTERN_METHOD(getRtcStatsReport:
                  (NSString*)publisherId)
RCT_EXTERN_METHOD(getSubscriberRtcStatsReport)
RCT_EXTERN_METHOD(subscribeToAudio:
                  (NSString*)streamId
                  subAudio:(BOOL)subAudio)
RCT_EXTERN_METHOD(subscribeToVideo:
                  (NSString*)streamId
                  subVideo:(BOOL)subVideo)
RCT_EXTERN_METHOD(subscribeToCaptions:
                  (NSString*)streamId
                  subCaptions:(BOOL)subCaptions)
RCT_EXTERN_METHOD(setPreferredResolution:
                  (NSString*)streamId
                  resolution:(NSDictionary*)resolution)
RCT_EXTERN_METHOD(setPreferredFrameRate:
                  (NSString*)streamId
                  frameRate:(nonnull NSNumber*)frameRate)
RCT_EXTERN_METHOD(setAudioVolume:
                  (NSString*)streamId
                  audioVolume:(nonnull NSNumber*)audioVolume)
RCT_EXTERN_METHOD(changeCameraPosition:
                  (NSString*)publisherId
                  cameraPosition:(NSString*)cameraPosition)
RCT_EXTERN_METHOD(changeVideoContentHint:
                  (NSString*)publisherId
                  videoContentHint:(NSString*)videoContentHint)
RCT_EXTERN_METHOD(setNativeEvents:
                  (NSArray*)events)
RCT_EXTERN_METHOD(removeNativeEvents:
                  (NSArray*)events)
RCT_EXTERN_METHOD(sendSignal:
                  (NSString*)sessionId
                  signal:(NSDictionary*)signal
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(setEncryptionSecret:
                  (NSString*)sessionId
                  secret:(NSString*)secret
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(destroyPublisher:
                  (NSString*)publisherId
                  callback:(RCTResponseSenderBlock)callback)
RCT_EXTERN_METHOD(setJSComponentEvents:
                  (NSArray*)events)
RCT_EXTERN_METHOD(setVideoTransformers:
                  (NSString*)publisherId
                  videoTransformers:(NSArray*)videoTransformers)
RCT_EXTERN_METHOD(removeJSComponentEvents:
                  (NSArray*)events)
RCT_EXTERN_METHOD(getSessionInfo:
                  (NSString*)sessionId
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(getSessionCapabilities:
                  (NSString*)sessionId
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(reportIssue:
                  (NSString*)sessionId
                  callback:(RCTResponseSenderBlock*)callback)
RCT_EXTERN_METHOD(getSupportedCodecs:
                  (RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(forceMuteAll:
                  (NSString*)sessionId
                  excludedStreamIds:(NSArray*)excludedStreamIds
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(forceMuteStream:
                  (NSString*)sessionId
                  streamId:(NSString*)streamId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(disableForceMute:
                  (NSString*)sessionId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(enableLogs:
                  (BOOL)logLevel)
@end
