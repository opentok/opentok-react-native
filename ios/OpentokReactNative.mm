#import <Foundation/Foundation.h>
#import <OpentokReactNative/RNOpentokReactNativeSpec.h>
#import <OpentokReactNative-Swift.h> 



typedef JS::NativeOpentokReactNative::SessionOptions RN_SessionOptions;

@interface OpentokReactNative : NativeOpentokReactNativeSpecBase <NativeOpentokReactNativeSpec>
@end

@implementation OpentokReactNative {
    OpentokReactNativeImpl *impl;
}

RCT_EXPORT_MODULE()

- (instancetype)init {
    self = [super init];
    if (self) {
      impl = [[OpentokReactNativeImpl alloc] initWithOt:self];
    }
    return self;
}

- (void) debugAlert:(NSString *) msg {
  // Create and show alert
  dispatch_async(dispatch_get_main_queue(), ^{
      UIAlertController *alert = [UIAlertController
          alertControllerWithTitle:@"Debug"
          message: msg
          preferredStyle:UIAlertControllerStyleAlert];
          
      [alert addAction:[UIAlertAction
          actionWithTitle:@"OK"
          style:UIAlertActionStyleDefault
          handler:nil]];
          
      UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
      [rootViewController presentViewController:alert animated:YES completion:nil];
  });
}
- (void)initSession:(nonnull NSString *)apiKey
          sessionId:(nonnull NSString *)sessionId
            options:(RN_SessionOptions &)options   {
  NSDictionary *optionsDict = @{};
  [impl initSession:apiKey sessionId:sessionId sessionOptions: optionsDict];
}

- (void)connect:(nonnull NSString *)sessionId 
          token:(nonnull NSString *)token 
        resolve:(nonnull RCTPromiseResolveBlock)resolve 
         reject:(nonnull RCTPromiseRejectBlock)reject {
    [impl connect:sessionId token:token resolve:resolve reject:reject];
}


- (void)disconnect:(nonnull NSString *)sessionId 
           resolve:(nonnull RCTPromiseResolveBlock)resolve 
            reject:(nonnull RCTPromiseRejectBlock)reject {
    [impl disconnect:sessionId resolve:resolve reject:reject];
}


- (void)getSubscriberRtcStatsReport { 
  
}


- (void)sendSignal:(nonnull NSString *)sessionId 
    type:(nonnull NSString *)type 
    data:(nonnull NSString *)data { 
  NSDictionary *signal = @{
    @"type": type,
    @"data": data
  };
  [impl sendSignal:sessionId signal:signal resolve:^(id result) {
    // Success case - nothing needed
  } reject:^(NSString *code, NSString *message, NSError *error) {
    // Error case - will be handled by the reject callback
  }];
}

- (void)setEncryptionSecret:(nonnull NSString *)sessionId 
                    secret:(nonnull NSString *)secret
                   resolve:(nonnull RCTPromiseResolveBlock)resolve 
                    reject:(nonnull RCTPromiseRejectBlock)reject {
    [impl setEncryptionSecret:sessionId secret:secret resolve:resolve reject:reject];
}

- (void)reportIssue:(nonnull NSString *)sessionId
            resolve:(nonnull RCTPromiseResolveBlock)resolve
             reject:(nonnull RCTPromiseRejectBlock)reject {
    [impl reportIssue:sessionId resolve:resolve reject:reject];
}

- (void)forceMuteAll:(nonnull NSString *)sessionId
    excludedStreamIds:(nonnull NSArray<NSString *> *)excludedStreamIds
             resolve:(nonnull RCTPromiseResolveBlock)resolve
              reject:(nonnull RCTPromiseRejectBlock)reject {
    [impl forceMuteAll:sessionId excludedStreamIds:excludedStreamIds resolve:resolve reject:reject];
}

- (void)forceMuteStream:(nonnull NSString *)sessionId
              streamId:(nonnull NSString *)streamId
               resolve:(nonnull RCTPromiseResolveBlock)resolve
                reject:(nonnull RCTPromiseRejectBlock)reject {
    [impl forceMuteStream:sessionId streamId:streamId resolve:resolve reject:reject];
}

- (void)disableForceMute:(nonnull NSString *)sessionId
                resolve:(nonnull RCTPromiseResolveBlock)resolve
                 reject:(nonnull RCTPromiseRejectBlock)reject {
    [impl disableForceMute:sessionId resolve:resolve reject:reject];
}

- (void)getPublisherRtcStatsReport:(nonnull NSString *)publisherId { 
      [impl getPublisherRtcStatsReport:publisherId];
}


- (void)publish:(nonnull NSString *)publisherId {
    [impl publish:publisherId];
}


- (void)setAudioTransformers:(nonnull NSString *)publisherId transformers:(nonnull NSArray *)transformers { 
    
}


- (void)setVideoTransformers:(nonnull NSString *)publisherId transformers:(nonnull NSArray *)transformers { 
    
}


//- (void)publish:(nonnull NSString *)publisherId
//        resolve:(nonnull RCTPromiseResolveBlock)resolve
//         reject:(nonnull RCTPromiseRejectBlock)reject {
//    [impl publish:publisherId resolve:resolve reject:reject];
//}


- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeOpentokReactNativeSpecJSI>(params);
}





@end
