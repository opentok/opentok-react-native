
@interface OTRNPublisherComponentView : UIView
- (void)handleStreamCreated:(NSDictionary *)eventData;
- (void)handleStreamDestroyed:(NSDictionary *)eventData;
- (void)handleError:(NSDictionary *)eventData;
- (void)handleAudioLevel:(float)audioLevel;
- (void)handleAudioNetworkStats:(NSString *)jsonString;
- (void)handleVideoNetworkStats:(NSString *)jsonString;
- (void)handleMuteForced;
- (void)handleRtcStatsReport:(NSString *)jsonString;
- (void)handleVideoDisableWarning;
- (void)handleVideoDisableWarningLifted;
- (void)handleVideoEnabled;
- (void)handleVideoDisabled;
@end
