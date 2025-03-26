
@interface OTPublisherViewNativeComponentView : UIView
- (void)handleStreamCreated:(NSDictionary *)eventData;
- (void)handleStreamDestroyed:(NSDictionary *)eventData;
- (void)handleError:(NSDictionary *)eventData;
- (void)handleAudioLevel:(NSDictionary *)eventData;
- (void)handleAudioNetworkStats:(NSString *)jsonString;
- (void)handleVideoNetworkStats:(NSString *)jsonString;
- (void)handleMuteForced;
- (void)handleRtcStatsReport:(NSDictionary *)eventData;
- (void)handleVideoDisableWarning;
- (void)handleVideoDisableWarningLifted;
- (void)handleVideoEnabled;
- (void)handleVideoDisabled;
@end
