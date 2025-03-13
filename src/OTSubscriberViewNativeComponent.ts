import type { HostComponent, ViewProps } from 'react-native';
import type { BubblingEventHandler } from 'react-native/Libraries/Types/CodegenTypes';
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

export interface NativeProps extends ViewProps {
  sessionId: string;
  streamId: string;
  subscribeToAudio?: boolean;
  subscribeToVideo?: boolean;
  onSubscriberConnected?: BubblingEventHandler<StreamEvent> | null;
  onStreamDestroyed?: BubblingEventHandler<StreamEvent> | null;
  onSubscriberError?: BubblingEventHandler<StreamErrorEvent> | null;
  onRtcStatsReport?: BubblingEventHandler<RTCStatsReportEvent> | null;
}

export default codegenNativeComponent<NativeProps>(
  'OTSubscriberViewNative'
) as HostComponent<NativeProps>;
