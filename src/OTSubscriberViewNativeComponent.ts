import type { HostComponent, ViewProps } from 'react-native';
import type {
  BubblingEventHandler,
  Int32,
  Float,
} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

export type StreamEvent = {
  streamId: string;
};

export type StreamErrorEvent = {
  streamId: string;
  errorMessage: string;
};

export type EmptyEvent = {};

export type SubscriberVideoNetworkStatsEvent = {
  jsonStats: string; // JSON string containing all video stats
};

export type SubscriberAudioStatsEvent = {
  jsonStats: string; // JSON string containing all audio stats
};

export type SubscriberAudioLevelEvent = {
  audioLevel: Float;
};



export type SubscriberRTCStatsReportEvent = {
  jsonStats: string;
};


export type SubscriberCaptionEvent = {
  text: string;
  isFinal: boolean;
};

export interface NativeProps extends ViewProps {
  sessionId: string;
  streamId: string;
  subscribeToAudio?: boolean;
  subscribeToVideo?: boolean;

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
  onVideoDisabled?: BubblingEventHandler<StreamEvent> | null;
  onVideoDisableWarning?: BubblingEventHandler<StreamEvent> | null;
  onVideoDisableWarningLifted?: BubblingEventHandler<StreamEvent> | null;
  onVideoEnabled?: BubblingEventHandler<StreamEvent> | null;
  onVideoNetworkStats?: BubblingEventHandler<SubscriberVideoNetworkStatsEvent> | null;
}

export default codegenNativeComponent<NativeProps>(
  'OTSubscriberViewNative'
) as HostComponent<NativeProps>;
