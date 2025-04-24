#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OpentokReactNative/ComponentDescriptors.h>
#import <OpentokReactNative/EventEmitters.h>
#import <OpentokReactNative/Props.h>
#import <OpentokReactNative/RCTComponentViewHelpers.h>
#import <OpentokReactNative/RNOpentokReactNativeSpec.h>
#import <React/RCTConversions.h>
#import <React/RCTViewComponentView.h>
#import <OpentokReactNative-Swift.h>

using namespace facebook::react;

@interface OTPublisherViewNativeComponentView
    : RCTViewComponentView <RCTOTPublisherViewNativeViewProtocol>
@end

@implementation OTPublisherViewNativeComponentView {
    OTPublisherViewNativeImpl *_impl;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
    return concreteComponentDescriptorProvider<
        OTPublisherViewNativeComponentDescriptor>();
}

- (NSDictionary *)createPublisherPropsFromViewProps:
    (const OTPublisherViewNativeProps &)viewProps {
    return @{
        @"sessionId" : RCTNSStringFromString(viewProps.sessionId),
        @"publisherId" : RCTNSStringFromString(viewProps.publisherId),
        @"videoTrack" : @(viewProps.videoTrack),
        @"audioTrack" : @(viewProps.audioTrack),
        @"audioBitrate" : @(viewProps.audioBitrate),
        @"frameRate" : @(viewProps.frameRate),
        @"resolution" : RCTNSStringFromString(viewProps.resolution),
        @"enableDtx" : @(viewProps.enableDtx),
        @"name" : RCTNSStringFromString(viewProps.name),
        @"publisherAudioFallback" : @(viewProps.publisherAudioFallback),
        @"subscriberAudioFallback" : @(viewProps.subscriberAudioFallback),
        @"videoContentHint" : RCTNSStringFromString(viewProps.videoContentHint),
        @"videoSource" : RCTNSStringFromString(viewProps.videoSource),
        @"cameraPosition" : RCTNSStringFromString(viewProps.cameraPosition),
        @"scalableScreenshare" : @(viewProps.scalableScreenshare),
        @"audioFallbackEnabled" : @(viewProps.audioFallbackEnabled),
        @"publishAudio" : @(viewProps.publishAudio),
        @"publishVideo" : @(viewProps.publishVideo),
        @"publishCaptions" : @(viewProps.publishCaptions)
    };
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _impl = [[OTPublisherViewNativeImpl alloc] initWithView:self];
        self.contentView = nil;
    }
    return self;
}

- (void)updateProps:(const Props::Shared &)props
           oldProps:(const Props::Shared &)oldProps {

    const auto &oldViewProps =
        *std::static_pointer_cast<const OTPublisherViewNativeProps>(_props);
    const auto &newViewProps =
        *std::static_pointer_cast<const OTPublisherViewNativeProps>(props);

    // Check if this is the first update (oldProps will be null/empty)
    if (!oldProps) {
        NSAssert(self.contentView == nil,
                 @"ContentView should be nil on first update");
        NSDictionary *publisherProperties =
            [self createPublisherPropsFromViewProps:newViewProps];
        [_impl createPublisher:publisherProperties];
        self.contentView = _impl.publisherView;
        return;
    }

    if (oldViewProps.sessionId != newViewProps.sessionId) {
        [_impl setSessionId:RCTNSStringFromString(newViewProps.sessionId)];
    }

    if (oldViewProps.publisherId != newViewProps.publisherId) {
        [_impl setPublisherId:RCTNSStringFromString(newViewProps.publisherId)];
    }

    if (oldViewProps.publishAudio != newViewProps.publishAudio) {
        [_impl setPublishAudio:newViewProps.publishAudio];
    }

    if (oldViewProps.publishVideo != newViewProps.publishVideo) {
        [_impl setPublishVideo:newViewProps.publishVideo];
    }

    [super updateProps:props oldProps:oldProps];
}

- (std::shared_ptr<const OTPublisherViewNativeEventEmitter>)getEventEmitter {
    if (!_eventEmitter) {
        return nullptr;
    }
    return std::static_pointer_cast<const OTPublisherViewNativeEventEmitter>(_eventEmitter);
}

- (void)handleStreamCreated:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnStreamCreated payload{
            .streamId = std::string([eventData[@"streamId"] UTF8String])};
        eventEmitter->onStreamCreated(std::move(payload));
    }
}

- (void)handleError:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnError payload{
            .code = std::string([eventData[@"code"] UTF8String]),
            .message = std::string([eventData[@"message"] UTF8String])};
        eventEmitter->onError(std::move(payload));
    }
}

- (void)handleStreamDestroyed:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnStreamDestroyed payload{
            .streamId = std::string([eventData[@"streamId"] UTF8String])};
        eventEmitter->onStreamDestroyed(std::move(payload));
    }
}

- (void)handleAudioLevel:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnAudioLevel payload{
            .audioLevel = [eventData[@"audioLevel"] floatValue]};
        eventEmitter->onAudioLevel(std::move(payload));
    }
}

- (void)handleAudioNetworkStats:(NSString *)jsonString {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnAudioNetworkStats payload{
            .json = std::string([jsonString UTF8String])};
        eventEmitter->onAudioNetworkStats(std::move(payload));
    }
}

- (void)handleVideoNetworkStats:(NSString *)jsonString {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnVideoNetworkStats payload{
            .json = std::string([jsonString UTF8String])};
        eventEmitter->onVideoNetworkStats(std::move(payload));
    }
}

- (void)handleMuteForced {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnMuteForced payload{};
        eventEmitter->onMuteForced(std::move(payload));
    }
}

- (void)handleRtcStatsReport:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnRtcStatsReport payload{
            .connectionId = std::string([eventData[@"connectionId"] UTF8String]),
            .jsonArrayOfReports = std::string([eventData[@"jsonArrayOfReports"] UTF8String])
        };
        eventEmitter->onRtcStatsReport(std::move(payload));
    }
}

- (void)handleVideoDisableWarning {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnVideoDisableWarning payload{};
        eventEmitter->onVideoDisableWarning(std::move(payload));
    }
}

- (void)handleVideoDisableWarningLifted {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnVideoDisableWarningLifted payload{};
        eventEmitter->onVideoDisableWarningLifted(std::move(payload));
    }
}

- (void)handleVideoEnabled {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTPublisherViewNativeEventEmitter::OnVideoEnabled payload{};
        eventEmitter->onVideoEnabled(std::move(payload));
    }
}
- (void)handleVideoDisabled {
    //TODO not there in ts
//    auto eventEmitter = [self getEventEmitter];
//    if (eventEmitter) {
//        OTPublisherViewNativeEventEmitter::OnVideoDisabled payload{};
//        eventEmitter->onVideoDisabled(std::move(payload));
//    }
}
@end

Class<RCTComponentViewProtocol> OTPublisherViewNativeCls(void) {
    return OTPublisherViewNativeComponentView.class;
}
