import { Platform } from 'react-native';

import { each, isString, isBoolean, isObject, isArray } from 'underscore';

import { handleError } from '../OTError';

const validateString = (value) => (isString(value) ? value : '');

const validateBoolean = (value) => (isBoolean(value) ? value : false);

const validateObject = (value) => (isObject(value) ? value : {});

const validateArray = (value) => (isArray(value) ? value : []);

// These objects will have key-value pairs, with the key
// being a session ID (e.g., eventHandlers[sessionId]):
const eventHandlers = {};

let streams = {};

let publisherStreams = {};

let connected = {};

const setIsConnected = (sessionId, value) => {
  connected[sessionId] = value;
};

const addStream = (sessionId, streamId) => {
  if (streams[sessionId] && !streams[sessionId].includes(streamId)) {
    streams[sessionId].push(streamId);
  }
};

const removeStream = (sessionId, streamId) => {
  if (!streams[sessionId]) return;
  const index = streams[sessionId].findIndex((obj) => obj === streamId);
  if (index !== -1) {
    streams[sessionId].splice(index, 1);
  }
};

const clearStreams = (sessionId) => {
  streams[sessionId] = [];
};

const getStreams = (sessionId) => streams[sessionId] || [];

const getPublisherStream = (sessionId) => publisherStreams[sessionId];

const isConnected = (sessionId) => connected[sessionId];

const dispatchEvent = (sessionId, type, event) => {
  if (!eventHandlers[sessionId]) {
    return;
  }
  const listeners = eventHandlers[sessionId][type];
  if (listeners) {
    listeners.forEach((listener) => {
      listener(event);
    });
  }
  if (type === 'publisherStreamCreated') {
    publisherStreams[sessionId] = event.streamId;
  }
  if (type === 'publisherStreamDestroyed') {
    delete publisherStreams[sessionId];
  }
};

const addEventListener = (sessionId, type, listener) => {
  if (!eventHandlers[sessionId]) {
    eventHandlers[sessionId] = {};
  }
  if (!eventHandlers[sessionId][type]) {
    eventHandlers[sessionId][type] = [listener];
  } else {
    eventHandlers[sessionId][type].push(listener);
  }
};

const removeEventListener = (sessionId, type, listener) => {
  if (eventHandlers[sessionId] && eventHandlers[sessionId][type]) {
    delete eventHandlers[sessionId][type];
  }
};

const sanitizeCustomTurnOptions = (options) => {
  let sessionOptions = {};
  if (typeof options !== 'object') {
    return {};
  }
  const validCustomTurnOptions = {
    includeServers: 'string',
    transportPolicy: 'string',
    filterOutLanCandidates: 'boolean',
    customServers: 'Array',
  };

  /*
  const customTurnOptions = {
    includeServers: 'all',
    transportPolicy: 'all',
    filterOutLanCandidates: 'boolean',
    customServers: [],
  };
  */

  each(options, (value, key) => {
    const optionType = validCustomTurnOptions[key];
    if (optionType !== undefined) {
      if (optionType === 'string') {
        sessionOptions[key] = validateString(value);
      } else if (optionType === 'Array') {
        sessionOptions[key] = validateArray(value);
      } else if (optionType === 'boolean') {
        sessionOptions[key] = validateBoolean(value);
      }
    } else {
      handleError(`${key} is not a valid option`);
    }
  });
  return sessionOptions;
};

const sanitizeSessionOptions = (options) => {
  const platform = Platform.OS;
  let sessionOptions;

  if (platform === 'android') {
    sessionOptions = {
      connectionEventsSuppressed: false,
      ipWhitelist: false,
      iceConfig: {},
      proxyUrl: '',
      useTextureViews: false,
      enableStereoOutput: false,
      androidOnTop: '', // 'publisher' || 'subscriber'
      androidZOrder: '', // 'mediaOverlay' || 'onTop'
      enableSinglePeerConnection: false,
      sessionMigration: false,
    };
  } else {
    sessionOptions = {
      connectionEventsSuppressed: false,
      ipWhitelist: false,
      iceConfig: {},
      proxyUrl: '',
      enableStereoOutput: false,
      enableSinglePeerConnection: false,
      sessionMigration: false,
    };
  }

  if (typeof options !== 'object') {
    return sessionOptions;
  }

  const validSessionOptions = {
    ios: {
      connectionEventsSuppressed: 'boolean',
      ipWhitelist: 'boolean',
      iceConfig: 'object',
      proxyUrl: 'string',
      enableStereoOutput: 'boolean',
      enableSinglePeerConnection: 'boolean',
      sessionMigration: 'boolean',
    },
    android: {
      connectionEventsSuppressed: 'boolean',
      useTextureViews: 'boolean',
      androidOnTop: 'string',
      androidZOrder: 'string',
      ipWhitelist: 'boolean',
      iceConfig: 'object',
      proxyUrl: 'string',
      enableStereoOutput: 'boolean',
      enableSinglePeerConnection: 'boolean',
      sessionMigration: 'boolean',
    },
  };

  each(options, (value, key) => {
    const optionType = validSessionOptions[platform][key];
    if (optionType !== undefined) {
      if (optionType === 'boolean') {
        sessionOptions[key] = validateBoolean(value);
      } else if (optionType === 'string') {
        sessionOptions[key] = validateString(value);
      } else if (optionType === 'object') {
        sessionOptions[key] = validateObject(value);
      }
    } else {
      handleError(`${key} is not a valid option`);
    }
  });

  if (sessionOptions.iceConfig) {
    const customTurnOptions = sanitizeCustomTurnOptions(
      sessionOptions.iceConfig
    );
    each(customTurnOptions, (value, key) => {
      sessionOptions[key] = customTurnOptions[key];
    });
  }
  return sessionOptions;
};

export {
  addStream,
  removeStream,
  clearStreams,
  getStreams,
  getPublisherStream,
  isConnected,
  setIsConnected,
  dispatchEvent,
  addEventListener,
  removeEventListener,
  sanitizeSessionOptions,
};
