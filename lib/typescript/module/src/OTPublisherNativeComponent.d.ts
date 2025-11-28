import type { HostComponent, ViewProps } from 'react-native';
import type { BubblingEventHandler, Int32, Float } from 'react-native/Libraries/Types/CodegenTypes';
export type StreamEvent = {
    streamId: string;
};
export type ErrorEvent = {
    code: string;
    message: string;
};
export type EmptyEvent = {};
export type PublisherVideoNetworkStatsEvent = {
    jsonStats: string;
};
export type AudioLevelEvent = {
    audioLevel: Float;
};
export type AudioNetworkStatsEvent = {
    jsonStats: string;
};
export type PublisherRTCStatsReportEvent = {
    jsonStats: string;
};
export interface NativeProps extends ViewProps {
    sessionId: string;
    publisherId: string;
    publishAudio?: boolean;
    publishVideo?: boolean;
    publishCaptions?: boolean;
    audioBitrate?: Int32;
    publisherAudioFallback?: boolean;
    subscriberAudioFallback?: boolean;
    audioTrack?: boolean;
    cameraPosition?: string;
    cameraTorch?: boolean;
    cameraZoomFactor?: Float;
    enableDtx?: boolean;
    frameRate?: Int32;
    name?: string;
    resolution?: string;
    scalableScreenshare?: boolean;
    allowAudioCaptureWhileMuted?: boolean;
    audioFallbackEnabled?: boolean;
    videoTrack?: boolean;
    videoSource?: string;
    videoContentHint?: string;
    maxVideoBitrate?: Int32;
    videoBitratePreset?: string;
    scaleBehavior?: string;
    onError?: BubblingEventHandler<ErrorEvent> | null;
    onStreamCreated?: BubblingEventHandler<StreamEvent> | null;
    onStreamDestroyed?: BubblingEventHandler<StreamEvent> | null;
    onAudioLevel?: BubblingEventHandler<AudioLevelEvent> | null;
    onAudioNetworkStats?: BubblingEventHandler<AudioNetworkStatsEvent> | null;
    onMuteForced?: BubblingEventHandler<EmptyEvent> | null;
    onRtcStatsReport?: BubblingEventHandler<PublisherRTCStatsReportEvent> | null;
    onVideoDisabled?: BubblingEventHandler<EmptyEvent> | null;
    onVideoDisableWarning?: BubblingEventHandler<EmptyEvent> | null;
    onVideoDisableWarningLifted?: BubblingEventHandler<EmptyEvent> | null;
    onVideoEnabled?: BubblingEventHandler<EmptyEvent> | null;
    onVideoNetworkStats?: BubblingEventHandler<PublisherVideoNetworkStatsEvent> | null;
}
declare const _default: HostComponent<NativeProps>;
export default _default;
//# sourceMappingURL=OTPublisherNativeComponent.d.ts.map