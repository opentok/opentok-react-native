import { sanitizeBooleanProperty, reassignEvents } from './OTHelper';

/**
 * This is the smallest positive int value for 2 bytes. Using Number.MAX_SAFE_INTEGER at JS level,
 * could drive to problems when coverted to the native layer (Android & iOS).
 * Since `32767` is a very high value for resolution and frame rate for all use case,
 * we won't have any problem for the foreseeable future
 */
const MAX_SAFE_INTEGER = 32767;

const sanitizeSubscriberEvents = (events) => {
  if (typeof events !== 'object') {
    return {};
  }
  const customEvents = {
    ios: {
      connected: 'subscriberDidConnect',
      disconnected: 'subscriberDidDisconnect',
      reconnected: 'subscriberDidReconnect',
      error: 'didFailWithError',
      audioNetworkStats: 'audioNetworkStatsUpdated',
      videoNetworkStats: 'videoNetworkStatsUpdated',
      audioLevel: 'audioLevelUpdated',
      videoDisabled: 'subscriberVideoDisabled',
      videoEnabled: 'subscriberVideoEnabled',
      videoDisableWarning: 'subscriberVideoDisableWarning',
      videoDisableWarningLifted: 'subscriberVideoDisableWarningLifted',
      videoDataReceived: 'subscriberVideoDataReceived',
    },
    android: {
      connected: 'onConnected',
      disconnected: 'onDisconnected',
      reconnected: 'onReconnected',
      error: 'onError',
      audioNetworkStats: 'onAudioStats',
      videoNetworkStats: 'onVideoStats',
      audioLevel: 'onAudioLevelUpdated',
      videoDisabled: 'onVideoDisabled',
      videoEnabled: 'onVideoEnabled',
      videoDisableWarning: 'onVideoDisableWarning',
      videoDisableWarningLifted: 'onVideoDisableWarningLifted',
      videoDataReceived: 'onVideoDataReceived',
    },
  };
  return reassignEvents('subscriber', customEvents, events);
};

const sanitizeResolution = (resolution) => {
  switch (resolution) {
    case null:
      return { width: MAX_SAFE_INTEGER, height: MAX_SAFE_INTEGER }
    case '352x288':
      return { width: 352, height: 288 };
    case '1280x720':
      return { width: 1280, height: 720 };
    case '640x480':
    default:
      return { width: 640, height: 480 };
  }
};

const sanitizeFrameRate = (frameRate) => {
  switch (frameRate) {
    case null:
      return MAX_SAFE_INTEGER;
    case 1:
      return 1;
    case 7:
      return 7;
    case 15:
      return 15;
    default:
      return 30;
  }
};

const sanitizeProperties = (properties) => {
  if (typeof properties !== 'object') {
    return {
      subscribeToAudio: true,
      subscribeToVideo: true,
      preferredResolution: sanitizeResolution(null),
      preferredFrameRate: sanitizeFrameRate(null)
    };
  }
  return {
    subscribeToAudio: sanitizeBooleanProperty(properties.subscribeToAudio),
    subscribeToVideo: sanitizeBooleanProperty(properties.subscribeToVideo),
    preferredResolution: sanitizeResolution(properties.preferredResolution),
    preferredFrameRate: sanitizeFrameRate(properties.preferredFrameRate)
  };
};

export {
  sanitizeSubscriberEvents,
  sanitizeProperties,
  sanitizeFrameRate,
  sanitizeResolution
};
