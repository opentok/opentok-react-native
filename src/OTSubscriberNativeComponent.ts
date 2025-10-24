import type { HostComponent, ViewProps } from 'react-native';
import type {
  BubblingEventHandler,
  Double,
  Float,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

export interface StreamEvent {
  stream: {
    name: string;
    streamId: string;
    hasAudio: boolean;
    hasCaptions: boolean;
    hasVideo: boolean;
    sessionId: string;
    width: Double;
    height: Double;
    videoType: string; //  "screen" | "camera";
    connection: {
      creationTime: string;
      data: string;
      connectionId: string;
    };
    creationTime: string;
  };
}

export interface StreamErrorEvent extends StreamEvent {
  error: {
    code: string;
    message: string;
  };
}

export type EmptyEvent = {};

export interface SubscriberVideoNetworkStatsEvent extends StreamEvent {
  jsonStats: string; // JSON string containing all video stats
}

export interface SubscriberAudioStatsEvent extends StreamEvent {
  jsonStats: string; // JSON string containing all audio stats
}

export interface SubscriberAudioLevelEvent extends StreamEvent {
  audioLevel: Float;
}

export interface SubscriberRTCStatsReportEvent extends StreamEvent {
  jsonStats: string;
}

export interface SubscriberCaptionEvent extends StreamEvent {
  text: string;
  isFinal: boolean;
}

export interface VideoDisabledEvent extends StreamEvent {
  reason: string;
}

export interface VideoEnabledEvent extends StreamEvent {
  reason: string;
}

export interface NativeProps extends ViewProps {
  sessionId: string;
  streamId: string;
  subscribeToAudio?: boolean;
  subscribeToVideo?: boolean;
  scaleBehavior?: string;

  subscribeToCaptions?: boolean;
  audioVolume?: Float;
  preferredFrameRate?: Int32;
  preferredResolution?: string;

  onSubscriberConnected?: BubblingEventHandler<StreamEvent> | null;
  onSubscriberDisconnected?: BubblingEventHandler<StreamEvent> | null;
  onSubscriberError?: BubblingEventHandler<StreamErrorEvent> | null;
  onRtcStatsReport?: BubblingEventHandler<SubscriberRTCStatsReportEvent> | null;
  onAudioLevel?: BubblingEventHandler<SubscriberAudioLevelEvent> | null;
  onAudioNetworkStats?: BubblingEventHandler<SubscriberAudioStatsEvent> | null;
  onCaptionReceived?: BubblingEventHandler<SubscriberCaptionEvent> | null;
  onVideoDataReceived?: BubblingEventHandler<StreamEvent> | null;
  onVideoDisabled?: BubblingEventHandler<VideoDisabledEvent> | null;
  onVideoDisableWarning?: BubblingEventHandler<StreamEvent> | null;
  onVideoDisableWarningLifted?: BubblingEventHandler<StreamEvent> | null;
  onVideoEnabled?: BubblingEventHandler<VideoEnabledEvent> | null;
  onVideoNetworkStats?: BubblingEventHandler<SubscriberVideoNetworkStatsEvent> | null;
}

export default codegenNativeComponent<NativeProps>(
  'OTRNSubscriber'
) as HostComponent<NativeProps>;
