import { sanitizeBooleanProperty } from './OTHelper';
import { each } from 'underscore';

/**
 * This is the smallest positive int value for 2 bytes. Using Number.MAX_SAFE_INTEGER at JS level,
 * could drive to problems when coverted to the native layer (Android & iOS).
 * Since `32767` is a very high value for resolution and frame rate for all use case,
 * we won't have any problem for the foreseeable future
 */
const MAX_SAFE_INTEGER = 32767;

const sanitizeResolution = (resolution) => {
  if (
    typeof resolution !== 'object' ||
    (resolution &&
      resolution.width === undefined && // TODO use typeof !== 'number'
      resolution.height === undefined) ||
    resolution === null
  ) {
    return { width: MAX_SAFE_INTEGER, height: MAX_SAFE_INTEGER };
  }
  const videoDimensions = {};
  if (resolution && resolution.height) {
    if (isNaN(parseInt(resolution.height, 10))) {
      videoDimensions.height = undefined;
    }

    videoDimensions.height = parseInt(resolution.height, 10);
  } else {
    videoDimensions.height = undefined;
  }
  if (resolution && resolution.width) {
    if (isNaN(parseInt(resolution.width, 10))) {
      videoDimensions.width = undefined;
    }

    videoDimensions.width = parseInt(resolution.width, 10);
  } else {
    videoDimensions.width = undefined;
  }
  return videoDimensions;
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

const sanitizeAudioVolume = (audioVolume) =>
  typeof audioVolume === 'number' ? audioVolume : 100;

const sanitizeProperties = (properties) => {
  if (typeof properties !== 'object') {
    return {
      subscribeToAudio: true,
      subscribeToVideo: true,
      subscribeToCaptions: false,
      preferredResolution: sanitizeResolution(null),
      preferredFrameRate: sanitizeFrameRate(null),
      audioVolume: 100,
      scaleBehavior: 'fill',
    };
  }
  return {
    subscribeToAudio: sanitizeBooleanProperty(properties.subscribeToAudio),
    subscribeToVideo: sanitizeBooleanProperty(properties.subscribeToVideo),
    subscribeToCaptions: sanitizeBooleanProperty(
      properties.subscribeToCaptions ? properties.subscribeToCaptions : false
    ),
    preferredResolution: sanitizeResolution(properties.preferredResolution),
    preferredFrameRate: sanitizeFrameRate(properties.preferredFrameRate),
    audioVolume: sanitizeAudioVolume(properties.audioVolume),
    scaleBehavior: properties.scaleBehavior ? properties.scaleBehavior : 'fill',
  };
};

const sanitizeStreamProperties = (streamProperties) => {
  each(streamProperties, (individualStreamProperties, streamId) => {
    const {
      subscribeToAudio,
      subscribeToVideo,
      subscribeToCaptions,
      preferredResolution,
      preferredFrameRate,
      audioVolume,
      scaleBehavior,
    } = individualStreamProperties;
    if (subscribeToAudio !== undefined) {
      individualStreamProperties.subscribeToAudio =
        sanitizeBooleanProperty(subscribeToAudio);
    }
    if (subscribeToVideo !== undefined) {
      individualStreamProperties.subscribeToVideo =
        sanitizeBooleanProperty(subscribeToVideo);
    }
    if (subscribeToCaptions !== undefined) {
      individualStreamProperties.subscribeToCaptions =
        sanitizeBooleanProperty(subscribeToCaptions);
    }
    if (preferredResolution !== undefined) {
      individualStreamProperties.preferredResolution =
        sanitizeResolution(preferredResolution);
    }
    if (preferredFrameRate !== undefined) {
      individualStreamProperties.preferredFrameRate =
        sanitizeFrameRate(preferredFrameRate);
    }
    if (audioVolume !== undefined) {
      individualStreamProperties.audioVolume = sanitizeAudioVolume(audioVolume);
    }
    if (scaleBehavior !== undefined) {
      individualStreamProperties.scaleBehavior = scaleBehavior;
    }
  });
};

export { sanitizeProperties, sanitizeStreamProperties };
