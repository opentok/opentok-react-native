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

const sanitizeProperties = (properties) => {
  if (typeof properties !== 'object') {
    return {
      subscribeToAudio: true,
      subscribeToVideo: true,
    };
  }
  return {
    subscribeToAudio: sanitizeBooleanProperty(properties.subscribeToAudio),
    subscribeToVideo: sanitizeBooleanProperty(properties.subscribeToVideo),
  };
};

export {
  sanitizeSubscriberEvents,
  sanitizeProperties,
};
