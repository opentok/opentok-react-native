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

@interface OTRNSubscriberComponentView : RCTViewComponentView <RCTOTRNSubscriberViewProtocol>
@end

@implementation OTRNSubscriberComponentView {
    OTRNSubscriberImpl *_impl;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
    return concreteComponentDescriptorProvider<OTRNSubscriberComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _impl = [[OTRNSubscriberImpl alloc] initWithView:self];
        self.contentView = nil;
    }
    return self;
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps {
    const auto &oldViewProps = *std::static_pointer_cast<const OTRNSubscriberProps>(_props);
    const auto &newViewProps = *std::static_pointer_cast<const OTRNSubscriberProps>(props);

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

//The view instance (and its _impl) is reused after recycling, not recreated.
- (void)prepareForRecycle {
    // Clean up native resources, observers, etc.
    if (_impl) {
      [_impl cleanup]; 
    }
    self.contentView = nil;
    [super prepareForRecycle];
}

- (std::shared_ptr<const OTRNSubscriberEventEmitter>)getEventEmitter {
    if (!_eventEmitter) {
        return nullptr;
    }
    return std::static_pointer_cast<const OTRNSubscriberEventEmitter>(_eventEmitter);
}

- (void)handleSubscriberConnected:(NSDictionary *)stream {
    NSDictionary *streamDict = stream[@"stream"];
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNSubscriberEventEmitter::OnSubscriberConnected payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnSubscriberConnectedStream,
                OTRNSubscriberEventEmitter::OnSubscriberConnectedStreamConnection
            >(streamDict)
        };
        eventEmitter->onSubscriberConnected(std::move(payload));
    }
}

- (void)handleSubscriberDisconnected:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNSubscriberEventEmitter::OnSubscriberDisconnected payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnSubscriberDisconnectedStream,
                OTRNSubscriberEventEmitter::OnSubscriberDisconnectedStreamConnection
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
        OTRNSubscriberEventEmitter::OnSubscriberErrorError errorStruct{
            .code = std::string([errorDict[@"code"] ?: @"" UTF8String]),
            .message = std::string([errorDict[@"message"] ?: @"" UTF8String])
        };
        OTRNSubscriberEventEmitter::OnSubscriberError payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnSubscriberErrorStream,
                OTRNSubscriberEventEmitter::OnSubscriberErrorStreamConnection
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
        OTRNSubscriberEventEmitter::OnRtcStatsReport payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnRtcStatsReportStream,
                OTRNSubscriberEventEmitter::OnRtcStatsReportStreamConnection
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
        OTRNSubscriberEventEmitter::OnAudioLevel payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnAudioLevelStream,
                OTRNSubscriberEventEmitter::OnAudioLevelStreamConnection
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
        OTRNSubscriberEventEmitter::OnVideoNetworkStats payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnVideoNetworkStatsStream,
                OTRNSubscriberEventEmitter::OnVideoNetworkStatsStreamConnection
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
        OTRNSubscriberEventEmitter::OnAudioNetworkStats payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnAudioNetworkStatsStream,
                OTRNSubscriberEventEmitter::OnAudioNetworkStatsStreamConnection
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
        OTRNSubscriberEventEmitter::OnVideoEnabled payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnVideoEnabledStream,
                OTRNSubscriberEventEmitter::OnVideoEnabledStreamConnection
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
        OTRNSubscriberEventEmitter::OnVideoDisabled payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnVideoDisabledStream,
                OTRNSubscriberEventEmitter::OnVideoDisabledStreamConnection
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
        OTRNSubscriberEventEmitter::OnVideoDisableWarning payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnVideoDisableWarningStream,
                OTRNSubscriberEventEmitter::OnVideoDisableWarningStreamConnection
            >(streamDict)
        };
        eventEmitter->onVideoDisableWarning(std::move(payload));
    }
}

- (void)handleVideoDisableWarningLifted:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNSubscriberEventEmitter::OnVideoDisableWarningLifted payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnVideoDisableWarningLiftedStream,
                OTRNSubscriberEventEmitter::OnVideoDisableWarningLiftedStreamConnection
            >(streamDict)
        };
        eventEmitter->onVideoDisableWarningLifted(std::move(payload));
    }
}

- (void)handleVideoDataReceived:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTRNSubscriberEventEmitter::OnVideoDataReceived payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnVideoDataReceivedStream,
                OTRNSubscriberEventEmitter::OnVideoDataReceivedStreamConnection
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
        OTRNSubscriberEventEmitter::OnCaptionReceived payload{
            .stream = makeStreamStruct<
                OTRNSubscriberEventEmitter::OnCaptionReceivedStream,
                OTRNSubscriberEventEmitter::OnCaptionReceivedStreamConnection
            >(streamDict),
            .text = std::string([text UTF8String]),
            .isFinal = isFinal
        };
        eventEmitter->onCaptionReceived(std::move(payload));
    }
}
@end

Class<RCTComponentViewProtocol> OTRNSubscriberCls(void) {
    return OTRNSubscriberComponentView.class;
}
