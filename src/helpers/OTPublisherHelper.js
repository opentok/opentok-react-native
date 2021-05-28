import { sanitizeBooleanProperty, reassignEvents } from './OTHelper';

const sanitizeResolution = (resolution) => {
  switch (resolution) {
    case '352x288':
      return 'LOW';
    case '640x480':
      return 'MEDIUM';
    case '1280x720':
      return 'HIGH';
    default:
      return 'MEDIUM';
  }
};

const sanitizeFrameRate = (frameRate) => {
  switch (frameRate) {
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

const sanitizeCameraPosition = (cameraPosition = 'front') => (cameraPosition === 'front' ? 'front' : cameraPosition);

const sanitizeVideoSource = (videoSource = 'camera') => (videoSource === 'camera' ? 'camera' : 'screen');

const sanitizeAudioBitrate = (audioBitrate = 40000) =>
  (audioBitrate < 6000 || audioBitrate > 510000 ? 40000 : audioBitrate);

const sanitizeScaleBehavior = (scaleBehavior = 'fill') => (scaleBehavior === 'fill' ? 'fill' : 'fit');

const sanitizeProperties = (properties) => {
  if (typeof properties !== 'object') {
    return {
      scaleBehavior: 'fill',
      videoTrack: true,
      audioTrack: true,
      publishAudio: true,
      publishVideo: true,
      name: '',
      cameraPosition: 'front',
      audioFallbackEnabled: true,
      audioBitrate: 40000,
      frameRate: 30,
      resolution: sanitizeResolution(),
      videoSource: 'camera',
    };
  }
  return {
    scaleBehavior: sanitizeScaleBehavior(properties.scaleBehavior),
    videoTrack: sanitizeBooleanProperty(properties.videoTrack),
    audioTrack: sanitizeBooleanProperty(properties.audioTrack),
    publishAudio: sanitizeBooleanProperty(properties.publishAudio),
    publishVideo: sanitizeBooleanProperty(properties.publishVideo),
    name: properties.name ? properties.name : '',
    cameraPosition: sanitizeCameraPosition(properties.cameraPosition),
    audioFallbackEnabled: sanitizeBooleanProperty(properties.audioFallbackEnabled),
    audioBitrate: sanitizeAudioBitrate(properties.audioBitrate),
    frameRate: sanitizeFrameRate(properties.frameRate),
    resolution: sanitizeResolution(properties.resolution),
    videoSource: sanitizeVideoSource(properties.videoSource),
  };
};

const sanitizePublisherEvents = (publisherId, events) => {
  if (typeof events !== 'object') {
    return {};
  }
  const customEvents = {
    ios: {
      streamCreated: 'streamCreated',
      streamDestroyed: 'streamDestroyed',
      error: 'didFailWithError',
      audioLevel: 'audioLevelUpdated',
    },
    android: {
      streamCreated: 'onStreamCreated',
      streamDestroyed: 'onStreamDestroyed',
      error: 'onError',
      audioLevel: 'onAudioLevelUpdated',
    },
  };
  return reassignEvents('publisher', customEvents, events, publisherId);
};

export {
  sanitizeScaleBehavior,
  sanitizeProperties,
  sanitizePublisherEvents,
};
