import { sanitizeBooleanProperty, reassignEvents } from './OTHelper';

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

const sanitizeResolution = resolution => (resolution && resolution.width && resolution.height ) ? resolution : {};

const sanitizeFrameRate = preferredFrameRate => (preferredFrameRate && !isNaN(preferredFrameRate)? parseFloat(preferredFrameRate) : 0);

const sanitizeProperties = (properties) => {
  if (typeof properties !== 'object') {
    return {
      subscribeToAudio: true,
      subscribeToVideo: true,
      preferredResolution: {},
      preferredFrameRate: 0
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
};
