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

- (void)handleSubscriberConnected:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnSubscriberConnected payload{
            .streamId = std::string([eventData[@"streamId"] UTF8String])
        };
        eventEmitter->onSubscriberConnected(std::move(payload));
    }
}

- (void)handleStreamDestroyed:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnStreamDestroyed payload{
            .streamId = std::string([eventData[@"streamId"] UTF8String])
        };
        eventEmitter->onStreamDestroyed(std::move(payload));
    }
}

- (void)handleError:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnSubscriberError payload{
            .streamId = std::string([eventData[@"streamId"] UTF8String]),
            .errorMessage = std::string([eventData[@"errorMessage"] UTF8String])
        };
        eventEmitter->onSubscriberError(std::move(payload));
    }
}

- (void)handleRtcStatsReport:(NSString *)jsonString {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnRtcStatsReport payload{
             .jsonStats = std::string([jsonString UTF8String])
        };
        eventEmitter->onRtcStatsReport(std::move(payload));
    }
}

- (void)handleAudioLevel:(float)audioLevel {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnAudioLevel payload{
            .audioLevel = audioLevel
        };
        eventEmitter->onAudioLevel(std::move(payload));
    }
}

- (void)handleVideoNetworkStats:(NSString *)jsonString {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnVideoNetworkStats payload{
            .jsonStats = std::string([jsonString UTF8String])
        };
        eventEmitter->onVideoNetworkStats(std::move(payload));
    }
}

- (void)handleAudioNetworkStats:(NSString *)jsonString {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        OTSubscriberViewNativeEventEmitter::OnAudioNetworkStats payload{
            .jsonStats = std::string([jsonString UTF8String])
        };
        eventEmitter->onAudioNetworkStats(std::move(payload));
    }
}

- (void)handleVideoEnabled:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        NSString *streamId = @"";
        if (eventData[@"stream"] && [eventData[@"stream"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *streamData = eventData[@"stream"];
            if (streamData[@"streamId"]) {
                streamId = streamData[@"streamId"];
            }
        }
        
        OTSubscriberViewNativeEventEmitter::OnVideoEnabled payload{
            .streamId = std::string([streamId UTF8String]),
           //TODO .reason = std::string([eventData[@"reason"] UTF8String])
        };
        eventEmitter->onVideoEnabled(std::move(payload));
    }
}

- (void)handleVideoDisabled:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        NSString *streamId = @"";
        if (eventData[@"stream"] && [eventData[@"stream"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *streamData = eventData[@"stream"];
            if (streamData[@"streamId"]) {
                streamId = streamData[@"streamId"];
            }
        }
        
        OTSubscriberViewNativeEventEmitter::OnVideoDisabled payload{
            .streamId = std::string([streamId UTF8String]),
            //.reason = std::string([eventData[@"reason"] UTF8String])
        };
        eventEmitter->onVideoDisabled(std::move(payload));
    }
}

- (void)handleVideoDisableWarning:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        NSString *streamId = @"";
        if (eventData[@"stream"] && [eventData[@"stream"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *streamData = eventData[@"stream"];
            if (streamData[@"streamId"]) {
                streamId = streamData[@"streamId"];
            }
        }
        
        OTSubscriberViewNativeEventEmitter::OnVideoDisableWarning payload{
            .streamId = std::string([streamId UTF8String])
        };
        eventEmitter->onVideoDisableWarning(std::move(payload));
    }
}

- (void)handleVideoDisableWarningLifted:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        NSString *streamId = @"";
        if (eventData[@"stream"] && [eventData[@"stream"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *streamData = eventData[@"stream"];
            if (streamData[@"streamId"]) {
                streamId = streamData[@"streamId"];
            }
        }
        
        OTSubscriberViewNativeEventEmitter::OnVideoDisableWarningLifted payload{
            .streamId = std::string([streamId UTF8String])
        };
        eventEmitter->onVideoDisableWarningLifted(std::move(payload));
    }
}

- (void)handleVideoDataReceived:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        NSString *streamId = @"";
        if (eventData[@"stream"] && [eventData[@"stream"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *streamData = eventData[@"stream"];
            if (streamData[@"streamId"]) {
                streamId = streamData[@"streamId"];
            }
        }
        
        OTSubscriberViewNativeEventEmitter::OnVideoDataReceived payload{
            .streamId = std::string([streamId UTF8String])
        };
        eventEmitter->onVideoDataReceived(std::move(payload));
    }
}

- (void)handleCaptionReceived:(NSDictionary *)eventData {
    auto eventEmitter = [self getEventEmitter];
    if (eventEmitter) {
        NSString *text = eventData[@"text"] ? [eventData[@"text"] description] : @"";
        BOOL isFinal = [eventData[@"isFinal"] boolValue];
        
        OTSubscriberViewNativeEventEmitter::OnCaptionReceived payload{
            .text = std::string([text UTF8String]),
            .isFinal = isFinal
        };
        eventEmitter->onCaptionReceived(std::move(payload));
    }
}

//TODO
//- (void)handleReconnected:(NSDictionary *)eventData {
//    auto eventEmitter = [self getEventEmitter];
//    if (eventEmitter) {
//        NSString *streamId = @"";
//        if (eventData[@"stream"] && [eventData[@"stream"] isKindOfClass:[NSDictionary class]]) {
//            NSDictionary *streamData = eventData[@"stream"];
//            if (streamData[@"streamId"]) {
//                streamId = streamData[@"streamId"];
//            }
//        }
//        
//        OTSubscriberViewNativeEventEmitter::OnReconnected payload{
//            .streamId = std::string([streamId UTF8String])
//        };
//        eventEmitter->onReconnected(std::move(payload));
//    }
//}

@end

Class<RCTComponentViewProtocol> OTSubscriberViewNativeCls(void) {
    return OTSubscriberViewNativeComponentView.class;
}
