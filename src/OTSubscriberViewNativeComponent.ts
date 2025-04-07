import type { HostComponent, ViewProps } from 'react-native';
import type { BubblingEventHandler, Double, Int32 } from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

type StreamEvent = {
  streamId: string;
};

type StreamErrorEvent = {
  streamId: string;
  errorMessage: string;
};

type RTCStatsReportEvent = {
  jsonArrayOfReports: string;
};

type SubscriberAudioLevelEvent = {
  audioLevel: Double;
};

type SubscriberAudioStatsEvent = {
  audioBytesReceived: Double;
  audioPacketsLost: Double;
  audioPacketsReceived: Double;
  timeStamp: Double;
};

type SubscriberCaptionEvent = {
  text: string;
  isFinal: boolean;
};

export interface NativeProps extends ViewProps {
  sessionId: string;
  streamId: string;
  subscribeToAudio?: boolean;
  subscribeToVideo?: boolean;

  subscribeToCaptions?: boolean;
  audioVolume?: Double;
  preferredFrameRate?: Int32;
  preferredResolution?: string;

  onSubscriberConnected?: BubblingEventHandler<StreamEvent> | null;
  onSubscriberDisconnected?: BubblingEventHandler<StreamEvent> | null;
  onStreamDestroyed?: BubblingEventHandler<StreamEvent> | null;
  onSubscriberError?: BubblingEventHandler<StreamErrorEvent> | null;
  onRtcStatsReport?: BubblingEventHandler<RTCStatsReportEvent> | null;
  onAudioLevel?: BubblingEventHandler<SubscriberAudioLevelEvent> | null;
  onAudioStates?: BubblingEventHandler<SubscriberAudioStatsEvent> | null;
  onCaptionReceived?: BubblingEventHandler<SubscriberCaptionEvent> | null;
  onVideoDataReceived?: BubblingEventHandler<StreamEvent> | null;
  onVideoDisabled?: BubblingEventHandler<StreamEvent> | null;
  onVideoDisableWarning?: BubblingEventHandler<StreamEvent> | null;
  onVideoDisableWarningLifted?: BubblingEventHandler<StreamEvent> | null;
  onVideoEnabled?: BubblingEventHandler<StreamEvent> | null;
  onVideoNetworkStats?: BubblingEventHandler<StreamEvent> | null;
}

export default codegenNativeComponent<NativeProps>(
  'OTSubscriberViewNative'
) as HostComponent<NativeProps>;
