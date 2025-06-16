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

template <typename T>
T makeConnectionStruct(NSDictionary *connectionDict) {
    return T{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };
}

template <typename StreamStruct, typename ConnectionStruct>
StreamStruct makeStreamStruct(NSDictionary *streamDict) {
    NSDictionary *connectionDict = streamDict[@"connection"] ?: @{};
    return StreamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = makeConnectionStruct<ConnectionStruct>(connectionDict),
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };
}

using namespace facebook::react;

@interface OTSubscriberViewNativeComponentView : RCTViewComponentView <RCTOTSubscriberViewNativeViewProtocol>
@end

@implementation OTSubscriberViewNativeComponentView {
    OTSubscriberViewNativeImpl *_impl;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
    return concreteComponentDescriptorProvider<OTSubscriberViewNativeComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _impl = [[OTSubscriberViewNativeImpl alloc] initWithView:self];
        self.contentView = nil;
    }
    return self;
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps {
    const auto &oldViewProps = *std::static_pointer_cast<const OTSubscriberViewNativeProps>(_props);
    const auto &newViewProps = *std::static_pointer_cast<const OTSubscriberViewNativeProps>(props);

    if (!oldProps) {
        // Check if this is the first update (oldProps will be null/empty)
        NSAssert(self.contentView == nil,
                 @"ContentView should be nil on first update");
        NSDictionary *subscriberProperties = @{
            @"sessionId": RCTNSStringFromString(newViewProps.sessionId),
            @"streamId": RCTNSStringFromString(newViewProps.streamId),
            @"subscribeToAudio": @(newViewProps.subscribeToAudio),
            @"subscribeToVideo": @(newViewProps.subscribeToVideo)
        };
        [_impl createSubscriber:subscriberProperties];
        self.contentView = _impl.subscriberView;
    }

    if (oldViewProps.sessionId != newViewProps.sessionId) {
        [_impl setSessionId:RCTNSStringFromString(newViewProps.sessionId)];
    }

    if (oldViewProps.streamId != newViewProps.streamId) {
        [_impl setStreamId:RCTNSStringFromString(newViewProps.streamId)];
    }

    if (oldViewProps.subscribeToAudio != newViewProps.subscribeToAudio) {
        [_impl setSubscribeToAudio:newViewProps.subscribeToAudio];
    }

    if (oldViewProps.subscribeToVideo != newViewProps.subscribeToVideo) {
        [_impl setSubscribeToVideo:newViewProps.subscribeToVideo];
    }

    [super updateProps:props oldProps:oldProps];
}

- (std::shared_ptr<const OTSubscriberViewNativeEventEmitter>)getEventEmitter {
    if (!_eventEmitter) {
        return nullptr;
    }
    return std::static_pointer_cast<const OTSubscriberViewNativeEventEmitter>(_eventEmitter);
}

- (void)handleSubscriberConnected:(NSDictionary *)stream {
    NSDictionary *streamDict = stream[@"stream"];
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnSubscriberConnected payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnSubscriberConnectedStream,
                OTSubscriberViewNativeEventEmitter::OnSubscriberConnectedStreamConnection
            >(streamDict)
        };
        eventEmitter->onSubscriberConnected(std::move(payload));
    }
}

- (void)handleSubscriberDisconnected:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnSubscriberDisconnected payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnSubscriberDisconnectedStream,
                OTSubscriberViewNativeEventEmitter::OnSubscriberDisconnectedStreamConnection
            >(streamDict)
        };
        eventEmitter->onSubscriberDisconnected(std::move(payload));
    }
}

- (void)handleError:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSDictionary *errorDict = eventData[@"error"];

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnSubscriberErrorError errorStruct{
            .code = std::string([errorDict[@"code"] ?: @"" UTF8String]),
            .message = std::string([errorDict[@"message"] ?: @"" UTF8String])
        };
        OTSubscriberViewNativeEventEmitter::OnSubscriberError payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnSubscriberErrorStream,
                OTSubscriberViewNativeEventEmitter::OnSubscriberErrorStreamConnection
            >(streamDict),
            .error = errorStruct
        };
        eventEmitter->onSubscriberError(std::move(payload));
    }
}

- (void)handleRtcStatsReport:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSString *jsonStats = eventData[@"jsonStats"] ?: @"";

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnRtcStatsReport payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnRtcStatsReportStream,
                OTSubscriberViewNativeEventEmitter::OnRtcStatsReportStreamConnection
            >(streamDict),
            .jsonStats = std::string([jsonStats UTF8String])
        };
        eventEmitter->onRtcStatsReport(std::move(payload));
    }
}

- (void)handleAudioLevel:(NSDictionary *)eventData {
    float audioLevel = [eventData[@"audioLevel"] floatValue];
    NSDictionary *streamDict = eventData[@"stream"];

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnAudioLevel payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnAudioLevelStream,
                OTSubscriberViewNativeEventEmitter::OnAudioLevelStreamConnection
            >(streamDict),
            .audioLevel = audioLevel
        };
        eventEmitter->onAudioLevel(std::move(payload));
    }
}

- (void)handleVideoNetworkStats:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSString *jsonStats = eventData[@"jsonStats"] ?: @"";

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoNetworkStats payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnVideoNetworkStatsStream,
                OTSubscriberViewNativeEventEmitter::OnVideoNetworkStatsStreamConnection
            >(streamDict),
            .jsonStats = std::string([jsonStats UTF8String])
        };
        eventEmitter->onVideoNetworkStats(std::move(payload));
    }
}

- (void)handleAudioNetworkStats:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSString *jsonStats = eventData[@"jsonStats"] ?: @"";

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnAudioNetworkStats payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnAudioNetworkStatsStream,
                OTSubscriberViewNativeEventEmitter::OnAudioNetworkStatsStreamConnection
            >(streamDict),
            .jsonStats = std::string([jsonStats UTF8String])
        };
        eventEmitter->onAudioNetworkStats(std::move(payload));
    }
}

- (void)handleVideoEnabled:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSString *reason = eventData[@"reason"] ?: @"";

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoEnabled payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnVideoEnabledStream,
                OTSubscriberViewNativeEventEmitter::OnVideoEnabledStreamConnection
            >(streamDict),
            .reason = std::string([reason UTF8String])
        };
        eventEmitter->onVideoEnabled(std::move(payload));
    }
}

- (void)handleVideoDisabled:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSString *reason = eventData[@"reason"] ?: @"";

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoDisabled payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnVideoDisabledStream,
                OTSubscriberViewNativeEventEmitter::OnVideoDisabledStreamConnection
            >(streamDict),
            .reason = std::string([reason UTF8String])
        };
        eventEmitter->onVideoDisabled(std::move(payload));
    }
}

- (void)handleVideoDisableWarning:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoDisableWarning payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningStream,
                OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningStreamConnection
            >(streamDict)
        };
        eventEmitter->onVideoDisableWarning(std::move(payload));
    }
}

- (void)handleVideoDisableWarningLifted:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningLifted payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningLiftedStream,
                OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningLiftedStreamConnection
            >(streamDict)
        };
        eventEmitter->onVideoDisableWarningLifted(std::move(payload));
    }
}

- (void)handleVideoDataReceived:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoDataReceived payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnVideoDataReceivedStream,
                OTSubscriberViewNativeEventEmitter::OnVideoDataReceivedStreamConnection
            >(streamDict)
        };
        eventEmitter->onVideoDataReceived(std::move(payload));
    }
}

- (void)handleCaptionReceived:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSString *text = eventData[@"text"] ? [eventData[@"text"] description] : @"";
    BOOL isFinal = [eventData[@"isFinal"] boolValue];

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnCaptionReceived payload{
            .stream = makeStreamStruct<
                OTSubscriberViewNativeEventEmitter::OnCaptionReceivedStream,
                OTSubscriberViewNativeEventEmitter::OnCaptionReceivedStreamConnection
            >(streamDict),
            .text = std::string([text UTF8String]),
            .isFinal = isFinal
        };
        eventEmitter->onCaptionReceived(std::move(payload));
    }
}
@end

Class<RCTComponentViewProtocol> OTSubscriberViewNativeCls(void) {
    return OTSubscriberViewNativeComponentView.class;
}
