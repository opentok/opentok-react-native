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

@interface OTRNPublisherComponentView
    : RCTViewComponentView <RCTOTRNPublisherViewProtocol>
@end

@implementation OTRNPublisherComponentView {
    OTRNPublisherImpl *_impl;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
    return concreteComponentDescriptorProvider<
        OTRNPublisherComponentDescriptor>();
}

- (NSDictionary *)createPublisherPropsFromViewProps:
    (const OTRNPublisherProps &)viewProps {
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
        @"cameraTorch" : @(viewProps.cameraTorch),
        @"cameraZoomFactor" : @(viewProps.cameraZoomFactor),
        @"videoSource" : RCTNSStringFromString(viewProps.videoSource),
        @"cameraPosition" : RCTNSStringFromString(viewProps.cameraPosition),
        @"scalableScreenshare" : @(viewProps.scalableScreenshare),
        @"audioFallbackEnabled" : @(viewProps.audioFallbackEnabled),
        @"publishAudio" : @(viewProps.publishAudio),
        @"publishVideo" : @(viewProps.publishVideo),
        @"publishCaptions" : @(viewProps.publishCaptions),
        @"allowAudioCaptureWhileMuted" : @(viewProps.allowAudioCaptureWhileMuted),
        @"maxVideoBitrate" : @(viewProps.maxVideoBitrate),
        @"videoBitratePreset" : RCTNSStringFromString(viewProps.videoBitratePreset),
        @"scaleBehavior": RCTNSStringFromString(viewProps.scaleBehavior),
    };
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _impl = [[OTRNPublisherImpl alloc] initWithView:self];
        self.contentView = nil;
    }
    return self;
}

- (void)updateProps:(const Props::Shared &)props
           oldProps:(const Props::Shared &)oldProps {

    const auto &oldViewProps =
        *std::static_pointer_cast<const OTRNPublisherProps>(_props);
    const auto &newViewProps =
        *std::static_pointer_cast<const OTRNPublisherProps>(props);

    // Check if this is the first update (oldProps will be null/empty)
    if (!oldProps) {
        NSAssert(self.contentView == nil,
                 @"ContentView should be nil on first update");
        NSDictionary *publisherProperties =
            [self createPublisherPropsFromViewProps:newViewProps];
        [_impl createPublisher:publisherProperties];
        self.contentView = _impl.publisherView;
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

    if (oldViewProps.videoContentHint != newViewProps.videoContentHint) {
        [_impl setVideoContentHint:RCTNSStringFromString(newViewProps.videoContentHint)];
    }

    if (oldViewProps.maxVideoBitrate != newViewProps.maxVideoBitrate) {
        [_impl setMaxVideoBitrate:(newViewProps.maxVideoBitrate)];
    }

    if (oldViewProps.videoBitratePreset != newViewProps.videoBitratePreset) {
        [_impl setVideoBitratePreset:RCTNSStringFromString(newViewProps.videoBitratePreset)];
    }

    if (oldViewProps.cameraTorch != newViewProps.cameraTorch) {
        [_impl setCameraTorch:newViewProps.cameraTorch];
    }

    if (oldViewProps.cameraZoomFactor != newViewProps.cameraZoomFactor) {
        [_impl setCameraZoomFactor:newViewProps.cameraZoomFactor];
    }

    if (oldViewProps.scaleBehavior != newViewProps.scaleBehavior) {
        NSLog(@"Setting scale behavior to %@", RCTNSStringFromString(newViewProps.scaleBehavior));
        [_impl setScaleBehavior:RCTNSStringFromString(newViewProps.scaleBehavior)];
    }

    [super updateProps:props oldProps:oldProps];
}

//The view instance (and its _impl) is reused after recycling, not recreated.
- (void)prepareForRecycle {
    if (_impl) {
       [_impl cleanup];
    }
    self.contentView = nil;
    [super prepareForRecycle];
}

- (std::shared_ptr<const OTRNPublisherEventEmitter>)getEventEmitter {
    if (!_eventEmitter) {
        return nullptr;
    }
    return std::static_pointer_cast<const OTRNPublisherEventEmitter>(_eventEmitter);
}

- (void)handleStreamCreated:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnStreamCreated payload{
            .streamId = std::string([eventData[@"streamId"] UTF8String])};
        eventEmitter->onStreamCreated(std::move(payload));
    }
}

- (void)handleError:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnError payload{
            .code = std::string([eventData[@"code"] UTF8String]),
            .message = std::string([eventData[@"message"] UTF8String])};
        eventEmitter->onError(std::move(payload));
    }
}

- (void)handleStreamDestroyed:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnStreamDestroyed payload{
            .streamId = std::string([eventData[@"streamId"] UTF8String])};
        eventEmitter->onStreamDestroyed(std::move(payload));
    }
}

- (void)handleAudioLevel:(float)audioLevel {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnAudioLevel payload{
            .audioLevel = audioLevel};
        eventEmitter->onAudioLevel(std::move(payload));
    }
}

- (void)handleAudioNetworkStats:(NSString *)jsonString {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnAudioNetworkStats payload{
            .jsonStats = std::string([jsonString UTF8String])};
        eventEmitter->onAudioNetworkStats(std::move(payload));
    }
}

- (void)handleVideoNetworkStats:(NSString *)jsonString {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnVideoNetworkStats payload{
            .jsonStats = std::string([jsonString UTF8String])};
        eventEmitter->onVideoNetworkStats(std::move(payload));
    }
}

- (void)handleMuteForced {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnMuteForced payload{};
        eventEmitter->onMuteForced(std::move(payload));
    }
}

- (void)handleRtcStatsReport:(NSString *)jsonString {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnRtcStatsReport payload{
            .jsonStats = std::string([jsonString UTF8String])
        };
        eventEmitter->onRtcStatsReport(std::move(payload));
    }
}

- (void)handleVideoDisableWarning {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnVideoDisableWarning payload{};
        eventEmitter->onVideoDisableWarning(std::move(payload));
    }
}

- (void)handleVideoDisableWarningLifted {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnVideoDisableWarningLifted payload{};
        eventEmitter->onVideoDisableWarningLifted(std::move(payload));
    }
}

- (void)handleVideoEnabled {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNPublisherEventEmitter::OnVideoEnabled payload{};
        eventEmitter->onVideoEnabled(std::move(payload));
    }
}
- (void)handleVideoDisabled {
    //TODO not there in ts
//    auto eventEmitter = [self getEventEmitter];
//    if (eventEmitter) {
//        OTRNPublisherEventEmitter::OnVideoDisabled payload{};
//        eventEmitter->onVideoDisabled(std::move(payload));
//    }
}
@end

Class<RCTComponentViewProtocol> OTRNPublisherCls(void) {
    return OTRNPublisherComponentView.class;
}
