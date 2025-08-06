

@interface OTRNSubscriberComponentView : UIView
- (void)handleSubscriberConnected:(NSDictionary *)eventData;
- (void)handleSubscriberDisconnected:(NSDictionary *)eventData;
- (void)handleError:(NSDictionary *)eventData;
- (void)handleRtcStatsReport:(NSDictionary *)eventData;
- (void)handleAudioLevel:(NSDictionary *)eventData;
- (void)handleVideoNetworkStats:(NSDictionary *)eventData;
- (void)handleAudioNetworkStats:(NSDictionary *)eventData;
- (void)handleVideoEnabled:(NSDictionary *)eventData;
- (void)handleVideoDisabled:(NSDictionary *)eventData;
- (void)handleVideoDisableWarning:(NSDictionary *)eventData;
- (void)handleVideoDisableWarningLifted:(NSDictionary *)eventData;
- (void)handleVideoDataReceived:(NSDictionary *)eventData;
- (void)handleReconnected:(NSDictionary *)eventData;
- (void)handleCaptionReceived:(NSDictionary *)eventData;
@end
