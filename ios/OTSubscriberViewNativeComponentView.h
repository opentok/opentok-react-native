

@interface OTSubscriberViewNativeComponentView : UIView
- (void)handleSubscriberConnected:(NSDictionary *)eventData;
- (void)handleStreamDestroyed:(NSDictionary *)eventData;
- (void)handleError:(NSDictionary *)eventData;
- (void)handleRtcStatsReport:(NSString *)jsonString;
- (void)handleAudioLevel:(NSDictionary *)eventData;
- (void)handleVideoNetworkStats:(NSString *)jsonString;
- (void)handleAudioNetworkStats:(NSString *)jsonString;
@end
