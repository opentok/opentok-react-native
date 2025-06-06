

@interface OTSubscriberViewNativeComponentView : UIView
- (void)handleSubscriberConnected:(NSDictionary *)eventData;
- (void)handleSubscriberDisconnected:(NSDictionary *)eventData;
- (void)handleError:(NSDictionary *)eventData;
- (void)handleRtcStatsReport:(NSString *)jsonString;
- (void)handleAudioLevel:(float)audioLevel;
- (void)handleVideoNetworkStats:(NSString *)jsonString;
- (void)handleAudioNetworkStats:(NSString *)jsonString;
- (void)handleVideoEnabled:(NSDictionary *)eventData;
- (void)handleVideoDisabled:(NSDictionary *)eventData;
- (void)handleVideoDisableWarning:(NSDictionary *)eventData;
- (void)handleVideoDisableWarningLifted:(NSDictionary *)eventData;
- (void)handleVideoDataReceived:(NSDictionary *)eventData;
- (void)handleReconnected:(NSDictionary *)eventData;
- (void)handleCaptionReceived:(NSDictionary *)eventData;
@end
