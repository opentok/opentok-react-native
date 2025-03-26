

@interface OTSubscriberViewNativeComponentView : UIView
- (void)handleSubscriberConnected:(NSDictionary *)eventData;
- (void)handleStreamDestroyed:(NSDictionary *)eventData;
- (void)handleError:(NSDictionary *)eventData;
- (void)handleRtcStatsReport:(NSDictionary *)eventData;
@end