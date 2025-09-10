import { sanitizeBooleanProperty } from './OTHelper';

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

const sanitizeCameraPosition = (cameraPosition = 'front') =>
  cameraPosition === 'front' ? 'front' : cameraPosition;

const sanitizeCameraTorch = (cameraTorch = false) => Boolean(cameraTorch);

const sanitizeCameraZoomFactor = (cameraZoomFactor = 1) =>
  Number(cameraZoomFactor);

const sanitizeVideoSource = (videoSource = 'camera') =>
  videoSource === 'camera' ? 'camera' : 'screen';

const sanitizeAudioBitrate = (audioBitrate = 40000) =>
  audioBitrate < 6000 || audioBitrate > 510000 ? 40000 : audioBitrate;

const sanitizeSubscriberAudioFallback = (
  audioFallback,
  audioFallbackEnabled,
  videoSource
) => {
  if (typeof audioFallback === 'undefined') {
    if (typeof audioFallbackEnabled !== 'undefined') {
      return !!audioFallbackEnabled;
    }
  }
  if (typeof audioFallback !== 'object') {
    return !(videoSource === 'screen');
  }
  if (typeof audioFallback.subscriber !== 'undefined') {
    return !!audioFallback.subscriber;
  }
  return !(videoSource === 'screen');
};

const sanitizePublisherAudioFallback = (audioFallback, videoSource) => {
  if (typeof audioFallback !== 'object') {
    return !(videoSource === 'screen');
  }
  if (typeof audioFallback.publisher !== 'undefined') {
    return !!audioFallback.publisher;
  }
  return !(videoSource === 'screen');
};

const sanitizeVideoContentHint = (videoContentHint = '') => {
  switch (videoContentHint) {
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

const sanitizeMaxVideoBitrate = (maxVideoBitrate) => {
  if (maxVideoBitrate && !isNaN(maxVideoBitrate)) {
    return Math.min(Math.max(maxVideoBitrate, 5000), 10000000);
  }
  return 0;
};

const sanitizeVideoBitratePreset = (videoBitratePreset, maxVideoBitrate) => {
  if (maxVideoBitrate) {
    return '';
  }
  switch (videoBitratePreset) {
    case 'bw_saver':
      return 'bw_saver';
    case 'extra_bw_saver':
      return 'extra_bw_saver';
    default:
      return 'default';
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
      cameraZoomFactor: 1,
      cameraTorch: false,
      cameraPosition: 'front',
      publisherAudioFallback: false,
      subscriberAudioFallback: true,
      audioBitrate: 40000,
      enableDtx: false,
      frameRate: 30,
      resolution: sanitizeResolution(),
      videoContentHint: '',
      videoSource: 'camera',
      scalableScreenshare: false,
      allowAudioCaptureWhileMuted: false,
    };
  }

  if (typeof properties.audioFallbackEnabled !== 'undefined') {
    console.log('audioFallbackEnabled is deprecated -- use audioFallback.');
    if (properties.audioFallback) {
      delete properties.audioFallbackEnabled;
    }
  }

  return {
    videoTrack: sanitizeBooleanProperty(properties.videoTrack),
    audioTrack: sanitizeBooleanProperty(properties.audioTrack),
    publishAudio: sanitizeBooleanProperty(properties.publishAudio),
    publishVideo: sanitizeBooleanProperty(properties.publishVideo),
    publishCaptions: sanitizeBooleanProperty(
      properties.publishCaptions ? properties.publishCaptions : false
    ),
    name: properties.name ? properties.name : '',
    cameraPosition: sanitizeCameraPosition(properties.cameraPosition),
    cameraTorch: sanitizeCameraTorch(properties.cameraTorch),
    cameraZoomFactor: sanitizeCameraZoomFactor(properties.cameraZoomFactor),
    publisherAudioFallback: sanitizePublisherAudioFallback(
      properties.audioFallback,
      properties.videoSource
    ),
    subscriberAudioFallback: sanitizeSubscriberAudioFallback(
      properties.audioFallback,
      properties.audioFallbackEnabled,
      properties.videoSource
    ),
    audioBitrate: sanitizeAudioBitrate(properties.audioBitrate),
    enableDtx: sanitizeBooleanProperty(
      properties.enableDtx ? properties.enableDtx : false
    ),
    frameRate: sanitizeFrameRate(properties.frameRate),
    resolution: sanitizeResolution(properties.resolution),
    videoContentHint: sanitizeVideoContentHint(properties.videoContentHint),
    videoSource: sanitizeVideoSource(properties.videoSource),
    scalableScreenshare: Boolean(properties.scalableScreenshare),
    allowAudioCaptureWhileMuted: Boolean(
      properties.allowAudioCaptureWhileMuted
    ),
    maxVideoBitrate: sanitizeMaxVideoBitrate(properties.videoBitratePreset),
    videoBitratePreset: sanitizeVideoBitratePreset(
      properties.videoBitratePreset,
      properties.maxVideoBitrate
    ),
  };
};

export { sanitizeProperties };
