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
    NSDictionary *connectionDict = streamDict[@"connection"];

    OTSubscriberViewNativeEventEmitter::OnSubscriberConnectedStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnSubscriberConnectedStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnSubscriberConnected payload{
            .stream = streamStruct
        };
        eventEmitter->onSubscriberConnected(std::move(payload));
    }
}

- (void)handleSubscriberDisconnected:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSDictionary *connectionDict = streamDict[@"connection"];

    OTSubscriberViewNativeEventEmitter::OnSubscriberDisconnectedStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnSubscriberDisconnectedStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnSubscriberDisconnected payload{
            .stream = streamStruct
        };
        eventEmitter->onSubscriberDisconnected(std::move(payload));
    }
}

- (void)handleError:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSDictionary *connectionDict = streamDict[@"connection"];
    NSDictionary *errorDict = eventData[@"error"];

    // Build connection struct
    OTSubscriberViewNativeEventEmitter::OnSubscriberErrorStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    // Build stream struct
    OTSubscriberViewNativeEventEmitter::OnSubscriberErrorStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnSubscriberErrorError errorStruct{
        .code = std::string([errorDict[@"code"] ?: @"" UTF8String]),
        .message = std::string([errorDict[@"message"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnSubscriberError payload{
            .stream = streamStruct,
            .error = errorStruct
        };
        eventEmitter->onSubscriberError(std::move(payload));
    }
}

- (void)handleRtcStatsReport:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSString *jsonStats = eventData[@"jsonStats"] ?: @"";

    // Build connection struct
    NSDictionary *connectionDict = streamDict[@"connection"];
    OTSubscriberViewNativeEventEmitter::OnRtcStatsReportStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    // Build stream struct
    OTSubscriberViewNativeEventEmitter::OnRtcStatsReportStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnRtcStatsReport payload{
            .stream = streamStruct,
            .jsonStats = std::string([jsonStats UTF8String])
        };
        eventEmitter->onRtcStatsReport(std::move(payload));
    }
}

// With stream and audioLevel
- (void)handleAudioLevel:(NSDictionary *)eventData {
    float audioLevel = [eventData[@"audioLevel"] floatValue];
    NSDictionary *streamDict = eventData[@"stream"];
    NSDictionary *connectionDict = streamDict[@"connection"];

    OTSubscriberViewNativeEventEmitter::OnAudioLevelStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnAudioLevelStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnAudioLevel payload{
            .stream = streamStruct,
            .audioLevel = audioLevel
        };
        eventEmitter->onAudioLevel(std::move(payload));
    }
}

- (void)handleVideoNetworkStats:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSString *jsonStats = eventData[@"jsonStats"] ?: @"";
    NSDictionary *connectionDict = streamDict[@"connection"];

    OTSubscriberViewNativeEventEmitter::OnVideoNetworkStatsStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnVideoNetworkStatsStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoNetworkStats payload{
            .stream = streamStruct,
            .jsonStats = std::string([jsonStats UTF8String])
        };
        eventEmitter->onVideoNetworkStats(std::move(payload));
    }
}

- (void)handleAudioNetworkStats:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSString *jsonStats = eventData[@"jsonStats"] ?: @"";
    NSDictionary *connectionDict = streamDict[@"connection"];

    OTSubscriberViewNativeEventEmitter::OnAudioNetworkStatsStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnAudioNetworkStatsStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnAudioNetworkStats payload{
            .stream = streamStruct,
            .jsonStats = std::string([jsonStats UTF8String])
        };
        eventEmitter->onAudioNetworkStats(std::move(payload));
    }
}

- (void)handleVideoEnabled:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSDictionary *connectionDict = streamDict[@"connection"];
    NSString *reason = eventData[@"reason"] ?: @"";

    OTSubscriberViewNativeEventEmitter::OnVideoEnabledStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnVideoEnabledStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoEnabled payload{
            .stream = streamStruct,
            .reason = std::string([reason UTF8String])
        };
        eventEmitter->onVideoEnabled(std::move(payload));
    }
}

- (void)handleVideoDisabled:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSDictionary *connectionDict = streamDict[@"connection"];
    NSString *reason = eventData[@"reason"] ?: @"";

    OTSubscriberViewNativeEventEmitter::OnVideoDisabledStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnVideoDisabledStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoDisabled payload{
            .stream = streamStruct,
            .reason = std::string([reason UTF8String])
        };
        eventEmitter->onVideoDisabled(std::move(payload));
    }
}

- (void)handleVideoDisableWarning:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSDictionary *connectionDict = streamDict[@"connection"];

    OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoDisableWarning payload{
            .stream = streamStruct
        };
        eventEmitter->onVideoDisableWarning(std::move(payload));
    }
}

- (void)handleVideoDisableWarningLifted:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSDictionary *connectionDict = streamDict[@"connection"];

    OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningLiftedStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningLiftedStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningLifted payload{
            .stream = streamStruct
        };
        eventEmitter->onVideoDisableWarningLifted(std::move(payload));
    }
}

- (void)handleVideoDataReceived:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSDictionary *connectionDict = streamDict[@"connection"];

    OTSubscriberViewNativeEventEmitter::OnVideoDataReceivedStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnVideoDataReceivedStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoDataReceived payload{
            .stream = streamStruct
        };
        eventEmitter->onVideoDataReceived(std::move(payload));
    }
}

- (void)handleCaptionReceived:(NSDictionary *)eventData {
    NSDictionary *streamDict = eventData[@"stream"];
    NSDictionary *connectionDict = streamDict[@"connection"];
    NSString *text = eventData[@"text"] ? [eventData[@"text"] description] : @"";
    BOOL isFinal = [eventData[@"isFinal"] boolValue];

    OTSubscriberViewNativeEventEmitter::OnCaptionReceivedStreamConnection connectionStruct{
        .creationTime = std::string([connectionDict[@"creationTime"] ?: @"" UTF8String]),
        .data = std::string([connectionDict[@"data"] ?: @"" UTF8String]),
        .connectionId = std::string([connectionDict[@"connectionId"] ?: @"" UTF8String])
    };

    OTSubscriberViewNativeEventEmitter::OnCaptionReceivedStream streamStruct{
        .name = std::string([streamDict[@"name"] ?: @"" UTF8String]),
        .streamId = std::string([streamDict[@"streamId"] ?: @"" UTF8String]),
        .hasAudio = [streamDict[@"hasAudio"] boolValue],
        .hasCaptions = [streamDict[@"hasCaptions"] boolValue],
        .hasVideo = [streamDict[@"hasVideo"] boolValue],
        .sessionId = std::string([streamDict[@"sessionId"] ?: @"" UTF8String]),
        .width = [streamDict[@"width"] doubleValue],
        .height = [streamDict[@"height"] doubleValue],
        .videoType = std::string([streamDict[@"videoType"] ?: @"" UTF8String]),
        .connection = connectionStruct,
        .creationTime = std::string([streamDict[@"creationTime"] ?: @"" UTF8String])
    };

    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnCaptionReceived payload{
            .stream = streamStruct,
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
