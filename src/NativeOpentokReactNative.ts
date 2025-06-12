import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import type { EventEmitter } from 'react-native/Libraries/Types/CodegenTypes';

export type ArchiveEvent = {
  archiveId: string;
  name: string;
  sessionId: string;
};

export type Connection = {
  creationTime: string;
  data: string;
  connectionId: string;
};

export type ConnectionEvent = {
  sessionId: string;
  connection: Connection;
};

export type EmptyEvent = {};

export type IceConfig = {
  includeServers: string; // 'all' | 'custom';
  transportPolicy: string; // 'all' | 'relay';
  customServers: {
    urls: string[];
    username?: string;
    credential?: string;
  }[];
};

export type MuteForcedEvent = {
  active: boolean;
};

export type SessionOptions = {
  androidZOrder?: string;
  connectionEventsSuppressed?: boolean;
  enableStereoOutput?: boolean;
  enableSinglePeerConnection?: boolean;
  iceConfig: IceConfig;
  ipWhitelist?: boolean;
  isCamera2Capable?: boolean;
  proxyUrl?: string;
  useTextureViews?: boolean;
};

export type SessionConnectEvent = {
  sessionId: string;
  connectionId: string;
};

export type SessionDisconnectEvent = Stream;

export type Stream = {
  name: string;
  streamId: string;
  hasAudio: boolean;
  hasCaptions: boolean;
  hasVideo: boolean;
  sessionId: string;
  width: number;
  height: number;
  videoType: string; //  "screen" | "camera";
  connection: Connection;
  creationTime: string;
};

export type StreamEvent = Stream;

export type StreamPropertyChangedEvent = {
  oldValue:
    | {
        width?: number;
        height?: number;
      }
    | boolean;
  newValue:
    | {
        width?: number;
        height?: number;
      }
    | boolean;
  stream: Stream;
  changedProperty: string;
};

export type SignalEvent = {
  sessionId: string;
  connectionId: string;
  type: string;
  data: string;
};

export type SessionErrorEvent = {
  code: string;
  message: string;
};

export interface Spec extends TurboModule {
  readonly onArchiveStarted: EventEmitter<ArchiveEvent>;
  readonly onArchiveStopped: EventEmitter<ArchiveEvent>;
  readonly onConnectionCreated: EventEmitter<ConnectionEvent>;
  readonly onConnectionDestroyed: EventEmitter<ConnectionEvent>;
  readonly onMuteForced: EventEmitter<MuteForcedEvent>;
  readonly onSessionConnected: EventEmitter<ConnectionEvent>;
  readonly onSessionDisconnected: EventEmitter<ConnectionEvent>;
  readonly onSessionReconnecting: EventEmitter<EmptyEvent>;
  readonly onSessionReconnected: EventEmitter<EmptyEvent>;
  readonly onStreamCreated: EventEmitter<StreamEvent>;
  readonly onStreamDestroyed: EventEmitter<StreamEvent>;
  readonly onStreamPropertyChanged: EventEmitter<StreamPropertyChangedEvent>;
  readonly onSignalReceived: EventEmitter<SignalEvent>;
  readonly onSessionError: EventEmitter<SessionErrorEvent>;
  initSession(
    apiKey: string,
    sessionId: string,
    options?: SessionOptions
  ): void;
  connect(sessionId: string, token: string): Promise<void>;
  disconnect(sessionId: string): Promise<void>;
  getSubscriberRtcStatsReport(): void;
  getPublisherRtcStatsReport(publisherId: string): void;
  setAudioTransformers(
    publisherId: string,
    transformers: Array<{
      name: string;
      properties?: string;
    }>
  ): void;
  setVideoTransformers(
    publisherId: string,
    transformers: Array<{
      name: string;
      properties?: string;
    }>
  ): void;
  publish(publisherId: string): void;
  sendSignal(sessionId: string, type: string, data: string): void;
  setEncryptionSecret(sessionId: string, secret: string): Promise<void>;
  reportIssue(sessionId: string): Promise<string>;
  forceMuteAll(
    sessionId: string,
    excludedStreamIds: string[]
  ): Promise<boolean>;
  forceMuteStream(sessionId: string, streamId: string): Promise<boolean>;
  disableForceMute(sessionId: string): Promise<boolean>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('OpentokReactNative');
