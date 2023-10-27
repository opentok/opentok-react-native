import { sanitizeBooleanProperty, reassignEvents } from './OTHelper';

const sanitizeResolution = (resolution) => {
  switch (resolution) {
    case '352x288':
      return 'LOW';
    case '640x480':
      return 'MEDIUM';
    case '1280x720':
      return 'HIGH';
    case '1920x1080':
      return 'HIGH_1080P';
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

const sanitizeVideoContentHint = (sanitizeVideoContentHint = '') => {
  switch (sanitizeVideoContentHint) {
    case 'motion':
      return 'motion';
    case 'detail':
      return 'detail';
    case 'text':
      return 'text';
    default:
      return '';
  }
};

const sanitizeProperties = (properties) => {
  if (typeof properties !== 'object') {
    return {
      videoTrack: true,
      audioTrack: true,
      publishAudio: true,
      publishVideo: true,
      publishCaptions: false,
      name: '',
      cameraPosition: 'front',
      audioFallbackEnabled: true,
      audioBitrate: 40000,
      enableDtx: false,
      frameRate: 30,
      resolution: sanitizeResolution(),
      videoContentHint: '',
      videoSource: 'camera',
      scalableScreenshare: false,
    };
  }
  return {
    videoTrack: sanitizeBooleanProperty(properties.videoTrack),
    audioTrack: sanitizeBooleanProperty(properties.audioTrack),
    publishAudio: sanitizeBooleanProperty(properties.publishAudio),
    publishVideo: sanitizeBooleanProperty(properties.publishVideo),
    publishCaptions: sanitizeBooleanProperty(properties.publishCaptions),
    name: properties.name ? properties.name : '',
    cameraPosition: sanitizeCameraPosition(properties.cameraPosition),
    audioFallbackEnabled: sanitizeBooleanProperty(properties.audioFallbackEnabled),
    audioBitrate: sanitizeAudioBitrate(properties.audioBitrate),
    enableDtx: sanitizeBooleanProperty(properties.enableDtx ? properties.enableDtx : false),
    frameRate: sanitizeFrameRate(properties.frameRate),
    resolution: sanitizeResolution(properties.resolution),
    videoContentHint: sanitizeVideoContentHint(properties.videoContentHint),
    videoSource: sanitizeVideoSource(properties.videoSource),
    scalableScreenshare: Boolean(properties.scalableScreenshare),
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
      audioNetworkStats: 'audioStats',
      rtcStatsReport: 'rtcStatsReport',
      videoNetworkStats: 'videoStats',
      muteForced: 'muteForced',
    },
    android: {
      streamCreated: 'onStreamCreated',
      streamDestroyed: 'onStreamDestroyed',
      error: 'onError',
      audioLevel: 'onAudioLevelUpdated',
      audioNetworkStats: 'onAudioStats',
      rtcStatsReport: 'onRtcStatsReport',
      videoNetworkStats: 'onVideoStats',
      muteForced: 'onMuteForced',
    },
  };
  return reassignEvents('publisher', customEvents, events, publisherId);
};

export {
  sanitizeProperties,
  sanitizePublisherEvents,
};
