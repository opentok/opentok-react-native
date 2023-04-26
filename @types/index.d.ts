declare module "opentok-react-native" {
  import React from "react";
  import { ViewProps } from "react-native";

  type Callback<T = void> = () => T;

  type CallbackWithParam<P, T = void> = (param: P) => T;

  type VideoSource = "screen" | "camera";

  interface SessionConnectEvent {
    sessionId: string;
    connection: Connection;
  }

  interface SessionDisconnectEvent {
    sessionId: string;
  }

  interface ConnectionCreatedEvent extends Connection {
    sessionId: string;
  }

  interface ConnectionDestroyedEvent extends Connection {
    sessionId: string;
  }

  interface StreamCreatedEvent extends Stream {}

  interface StreamDestroyedEvent extends Stream {}

  interface SubscriberAudioLevelEvent {
    audioLevel: number;
    stream: Stream;
  }

  interface Stream {
    name: string;
    streamId: string;
    hasAudio: boolean;
    hasVideo: boolean;
    sessionId: string;
    connectionId: string;
    width: number;
    height: number;
    videoType: VideoSource;
    connection: Connection;
    creationTime: string;
  }

  interface Connection {
    creationTime: string;
    data: string;
    connectionId: string;
  }

  interface StreamPropertyChangedEvent {
    newValue: any;
    oldValue: any;
    changedProperty: "hasAudio" | "hasVideo" | "videoDimensions";
    stream: Stream;
  }

  interface ArchiveEvent {
    archiveId: string;
    name: string;
    sessionId: string;
  }

  interface ErrorEvent {
    code: string;
    message: string;
  }
  
  interface SubscriberAudioStatsEvent {
    audioBytesReceived: number,
    audioPacketsLost: number,
    audioPacketsReceived: number,
    timeStamp: number,
  }

  interface VideoNetworkStatsEvent {
    videoPacketsLost: number,
    videoBytesReceived: number,
    videoPacketsReceived: number,
    timestamp: number,
  }

  interface SignalEvent {
    sessionId: string;
    fromConnection: string;
    type: string;
    data: string;
  }

  interface OTSessionProps extends ViewProps {
    /**
     * TokBox API Key
     */
    apiKey: string;

    /**
     * TokBox Session ID
     */
    sessionId: string;

    /**
     * TokBox token
     */
    token: string;

    /**
     * Used to define session options
     */
    options?: OTSessionSessionOptions;

    /**
     * Used to send a signal to the session
     */
    signal?: any;

    /**
     * Used to get details about the session
     */
    getSessionInfo?: any

    /**
     * Event handlers passed into the native session instance.
     */
    eventHandlers?: OTSessionEventHandlers;
  }

  interface OTSessionSessionOptions {
    /**
     * default is false
     */
    connectionEventsSuppressed?: boolean;

    /**
     * EU proxy server URL provided by vonage. Please check https://tokbox.com/developer/guides/eu-proxy/
     */
     proxyUrl?: string;

     /**
     * Android only - valid options are 'mediaOverlay' or 'onTop'
     */
    androidZOrder?: "mediaOverlay" | "onTop";

    /**
     * Android only - valid options are 'publisher' or 'subscriber'
     */
    androidOnTop?: "publisher" | "subscriber";

    /**
     * Android only - default is false
     */
    useTextureViews?: boolean;

    /**
     * Android only - default is false.
     * Deprecated and ignored.
     
     */
    isCamera2Capable?: boolean;

    /**
     * Whether to use the allowed IP list feature - default is false
     */
    ipWhitelist?: boolean;
    
    /**
     * Enable Stereo output
     */
    enableStereoOutput?: boolean;
    /**
     * Ice Config. Please check https://tokbox.com/developer/guides/configurable-turn-servers/
     */
    iceConfig?: {
      includeServers: 'all' | 'custom';
      transportPolicy: 'all' | 'relay';
      customServers: {
      urls: string[];
      username?: string;
      credential?: string;
      }[];
    };
  }

  interface OTSessionEventHandlers {
    /**
     * Sent when an archive recording of a session starts. If you connect to a session in which recording is already in progress, this message is sent when you connect.
     */
    archiveStarted?: CallbackWithParam<ArchiveEvent, any>;

    /**
     * Sent when an archive recording of a session stops.
     */
    archiveStopped?: CallbackWithParam<ArchiveEvent, any>;

    /**
     * Sent when another client connects to the session. The connection object represents the client’s connection.
     */
    connectionCreated?: CallbackWithParam<ConnectionCreatedEvent, any>;

    /**
     * Sent when another client disconnects from the session. The connection object represents the connection that the client had to the session.
     */
    connectionDestroyed?: CallbackWithParam<ConnectionDestroyedEvent, any>;

    /**
     * Sent if the attempt to connect to the session fails or if the connection to the session drops due to an error after a successful connection.
     */
    error?: CallbackWithParam<ErrorEvent, any>;

    /**
     * Sent if there is an error with the communication between the native session instance and the JS component.
     */
    otrnError?: CallbackWithParam<any, any>;

    /**
     * Sent when the client connects to the session.
     */
    sessionConnected?: CallbackWithParam<SessionConnectEvent, any>;

    /**
     * Sent when the client disconnects from the session.
     */
    sessionDisconnected?: CallbackWithParam<SessionDisconnectEvent, any>;

    /**
     * Sent when the local client has reconnected to the OpenTok session after its network connection was lost temporarily.
     */
    sessionReconnected?: CallbackWithParam<any>;

    /**
     * Sent when the local client has lost its connection to an OpenTok session and is trying to reconnect. This results from a loss in network connectivity. If the client can reconnect to the session, the sessionReconnected message is sent. Otherwise, if the client cannot reconnect, the sessionDisconnected message is sent.
     */
    sessionReconnecting?: Callback<any>;

    /**
     * Sent when the client receives a signal.
     */
    signal?: CallbackWithParam<SignalEvent, any>;

    /**
     * Sent when a new stream is created in this session.
     */
    streamCreated?: CallbackWithParam<StreamCreatedEvent, any>;

    /**
     * Sent when a stream is no longer published to the session.
     */
    streamDestroyed?: CallbackWithParam<StreamDestroyedEvent, any>;

    /**
     * Sent when a stream has started or stopped publishing audio or video or if the video dimensions of the stream have changed.
     */
    streamPropertyChanged?: CallbackWithParam<StreamPropertyChangedEvent, any>;
  }

  /**
   * https://github.com/opentok/opentok-react-native/blob/master/docs/OTSession.md
   */
  export class OTSession extends React.Component<OTSessionProps> {}

  interface OTPublisherProps extends ViewProps {
    /**
     * Properties passed into the native publisher instance
     */
    properties?: OTPublisherProperties;

    /**
     * Event handlers passed into native publsiher instance
     */
    eventHandlers?: OTPublisherEventHandlers;
  }

  interface OTPublisherProperties {
    /**
     * The desired bitrate for the published audio, in bits per second. The supported range of values is 6,000 - 510,000. (Invalid values are ignored.) Set this value to enable high-quality audio (or to reduce bandwidth usage with lower-quality audio). The following are recommended settings:
     * 8,000 - 12,000 for narrowband (NB) speech
     * 16,000 - 20,000 for wideband (WB) speech
     * 28,000 - 40,000 for full-band (FB) speech
     * 48,000 - 64,000 for full-band (FB) music
     * 64,000 - 128,000 for full-band (FB) stereo music
     * The default value is 40,000.
     */
    audioBitrate?: number;

    /**
     * Whether to turn on audio fallback or not.
     */
    audioFallbackEnabled?: boolean;

    /**
     * If this property is set to false, the audio subsystem will not be initialized for the publisher, and setting the publishAudio property will have no effect. If your application does not require the use of audio, it is recommended to set this property rather than use the publishAudio property, which only temporarily disables the audio track.
     */
    audioTrack?: boolean;

    /**
     * The preferred camera position. When setting this property, if the change is possible, the publisher will use the camera with the specified position. Valid Inputs: 'front' or 'back'
     */
    cameraPosition?: "front" | "back";

    /**
     * Whether to enable Opus DTX. The default value is false. Setting this to true can reduce bandwidth usage in streams that have long periods of silence.
     */
    enableDtx?: boolean;

    /**
     * The desired frame rate, in frames per second, of the video. Valid values are 30, 15, 7, and 1. The published stream will use the closest value supported on the publishing client. The frame rate can differ slightly from the value you set, depending on the device of the client. And the video will only use the desired frame rate if the client configuration supports it.
     */
    frameRate?: 30 | 15 | 7 | 1;

    /**
     * A string that will be associated with this publisher’s stream. This string is displayed at the bottom of publisher videos and at the bottom of subscriber videos associated with the published stream. If you do not specify a value, the name is set to the device name.
     */
    name?: string;

    /**
     * Whether to publish audio.
     */
    publishAudio?: boolean;

    /**
     * Whether to publish video.
     */
    publishVideo?: boolean;

    /**
     * The desired resolution of the video. The format of the string is "widthxheight", where the width and height are represented in pixels. Valid values are "1280x720", "640x480", and "352x288". The published video will only use the desired resolution if the client configuration supports it. Some devices and clients do not support each of these resolution settings.
     */
    resolution?: "1280x720" | "640x480" | "352x288";

    /**
     * If this property is set to false, the video subsystem will not be initialized for the publisher, and setting the publishVideo property will have no effect. If your application does not require the use of video, it is recommended to set this property rather than use the publishVideo property, which only temporarily disables the video track.
     */
    videoTrack?: boolean;

    /**
     * To publish a screen-sharing stream, set this property to "screen". If you do not specify a value, this will default to "camera".
     */
    videoSource?: VideoSource;
  }

  interface OTPublisherEventHandlers {
    /**
     * The audio level, from 0 to 1.0. Adjust this value logarithmically for use in adjusting a user interface element, such as a volume meter. Use a moving average to smooth the data.
     */
    audioLevel?: CallbackWithParam<number>;

    /**
     * Sent if the publisher encounters an error. After this message is sent, the publisher can be considered fully detached from a session and may be released.
     */
    error?: CallbackWithParam<any, any>;

    /**
     * Sent if there is an error with the communication between the native publisher instance and the JS component.
     */
    otrnError?: CallbackWithParam<any, any>;

    /**
     * Sent when the publisher starts streaming.
     */
    streamCreated?: CallbackWithParam<StreamCreatedEvent, any>;

    /**
     * Sent when the publisher stops streaming.
     */
    streamDestroyed?: CallbackWithParam<StreamDestroyedEvent, any>;
  }

  /**
   * https://github.com/opentok/opentok-react-native/blob/master/docs/OTPublisher.md
   */
  export class OTPublisher extends React.Component<OTPublisherProps> {}

  interface OTSubscriberProps extends ViewProps {
    /**
     * OpenTok Session ID. This is auto populated by wrapping OTSubscriber with OTSession
     */
    sessionId?: string;

    /**
     * OpenTok Subscriber streamId. This is auto populated inside the OTSubscriber component when streamCreated event is fired from the native instance
     */
    streamId?: string;

    /**
     * Properties passed into the native subscriber instance
     */
    properties?: OTSubscriberProperties;

    /**
     * Used to update individual subscriber instance properties
     */
    streamProperties?: any;

    /**
     * Event handlers passed into the native subscriber instance
     */
    eventHandlers?: OTSubscriberEventHandlers;

    /**
     * If set to true, the subscriber can subscribe to it's own publisher stream (default: false)
     */
    subscribeToSelf?: boolean;
  }

  interface OTSubscriberProperties {
    /**
     * Whether to subscribe to audio.
     */
    subscribeToAudio?: boolean;

    /**
     * Whether to subscribe video.
     */
    subscribeToVideo?: boolean;
  }

  interface OTSubscriberEventHandlers {
    /**
     * Sent on a regular interval with the recent representative audio level.
     */
    audioLevel?: CallbackWithParam<SubscriberAudioLevelEvent, any>;

    /**
     * Sent periodically to report audio statistics for the subscriber.
     */
    audioNetworkStats?: CallbackWithParam<SubscriberAudioStatsEvent, any>;

    /**
     * Sent when the subscriber successfully connects to the stream.
     */
    connected?: Callback<any>;

    /**
     * Called when the subscriber’s stream has been interrupted.
     */
    disconnected?: Callback<any>;

    /**
     * Sent if the subscriber fails to connect to its stream.
     */
    error?: CallbackWithParam<any, any>;

    /**
     * Sent if there is an error with the communication between the native subscriber instance and the JS component.
     */
    otrnError?: CallbackWithParam<any, any>;

    /**
     * Sent when a frame of video has been decoded. Although the subscriber will connect in a relatively short time, video can take more time to synchronize. This message is sent after the connected message is sent.
     */
    videoDataReceived?: Callback<any>;

    /**
     * This message is sent when the subscriber stops receiving video. Check the reason parameter for the reason why the video stopped.
     */
    videoDisabled?: CallbackWithParam<{reason: string; stream: Stream}, any>;

    /**
     * This message is sent when the OpenTok Media Router determines that the stream quality has degraded and the video will be disabled if the quality degrades further. If the quality degrades further, the subscriber disables the video and the videoDisabled message is sent. If the stream quality improves, the videoDisableWarningLifted message is sent.
     */
    videoDisableWarning?: Callback<any>;

    /**
     * This message is sent when the subscriber’s video stream starts (when there previously was no video) or resumes (after video was disabled). Check the reason parameter for the reason why the video started (or resumed).
     */
    videoDisableWarningLifted?: Callback<any>;

    /**
     * This message is sent when the subscriber’s video stream starts (when there previously was no video) or resumes (after video was disabled). Check the reason parameter for the reason why the video started (or resumed).
     */
    videoEnabled?: CallbackWithParam<{reason: string; stream: Stream}, any>;

    /**
     * Sent periodically to report video statistics for the subscriber.
     */
    videoNetworkStats?: CallbackWithParam<VideoNetworkStatsEvent, any>;
  }

  interface OTSubscriberViewProps extends ViewProps {
    /**
     * OpenTok Subscriber streamId.
     */
    streamId?: string;
  }

  /**
   * https://github.com/opentok/opentok-react-native/blob/main/docs/OTSubscriber.md#custom-rendering-of-streams
   */
  export class OTSubscriberView extends React.Component<OTSubscriberViewProps> {}
  /**
   * https://github.com/opentok/opentok-react-native/blob/master/docs/OTSubscriber.md
   */
  export class OTSubscriber extends React.Component<OTSubscriberProps> {}
}
