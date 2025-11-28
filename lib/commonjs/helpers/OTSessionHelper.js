"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.setIsConnected = exports.sanitizeSessionOptions = exports.removeStream = exports.removeEventListener = exports.isConnected = exports.getStreams = exports.getPublisherStream = exports.dispatchEvent = exports.clearStreams = exports.addStream = exports.addEventListener = void 0;
var _reactNative = require("react-native");
var _underscore = require("underscore");
var _OTError = require("../OTError.js");
const validateString = value => (0, _underscore.isString)(value) ? value : '';
const validateBoolean = value => (0, _underscore.isBoolean)(value) ? value : false;
const validateObject = value => (0, _underscore.isObject)(value) ? value : {};
const validateArray = value => (0, _underscore.isArray)(value) ? value : [];

// These objects will have key-value pairs, with the key
// being a session ID (e.g., eventHandlers[sessionId]):
const eventHandlers = {};
let streams = {};
let publisherStreams = {};
let connected = {};
const setIsConnected = (sessionId, value) => {
  connected[sessionId] = value;
};
exports.setIsConnected = setIsConnected;
const addStream = (sessionId, streamId) => {
  if (streams[sessionId] && !streams[sessionId].includes(streamId)) {
    streams[sessionId].push(streamId);
  }
};
exports.addStream = addStream;
const removeStream = (sessionId, streamId) => {
  if (!streams[sessionId]) return;
  const index = streams[sessionId].findIndex(obj => obj === streamId);
  if (index !== -1) {
    streams[sessionId].splice(index, 1);
  }
};
exports.removeStream = removeStream;
const clearStreams = sessionId => {
  streams[sessionId] = [];
};
exports.clearStreams = clearStreams;
const getStreams = sessionId => streams[sessionId] || [];
exports.getStreams = getStreams;
const getPublisherStream = sessionId => publisherStreams[sessionId];
exports.getPublisherStream = getPublisherStream;
const isConnected = sessionId => connected[sessionId];
exports.isConnected = isConnected;
const dispatchEvent = (sessionId, type, event) => {
  if (!eventHandlers[sessionId]) {
    return;
  }
  const listeners = eventHandlers[sessionId][type];
  if (listeners) {
    listeners.forEach(listener => {
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
exports.dispatchEvent = dispatchEvent;
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
exports.addEventListener = addEventListener;
const removeEventListener = (sessionId, type, listener) => {
  if (eventHandlers[sessionId] && eventHandlers[sessionId][type]) {
    delete eventHandlers[sessionId][type];
  }
};
exports.removeEventListener = removeEventListener;
const sanitizeCustomTurnOptions = options => {
  let sessionOptions = {};
  if (typeof options !== 'object') {
    return {};
  }
  const validCustomTurnOptions = {
    includeServers: 'string',
    transportPolicy: 'string',
    filterOutLanCandidates: 'boolean',
    customServers: 'Array'
  };

  /*
  const customTurnOptions = {
    includeServers: 'all',
    transportPolicy: 'all',
    filterOutLanCandidates: 'boolean',
    customServers: [],
  };
  */

  (0, _underscore.each)(options, (value, key) => {
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
      (0, _OTError.handleError)(`${key} is not a valid option`);
    }
  });
  return sessionOptions;
};
const sanitizeSessionOptions = options => {
  const platform = _reactNative.Platform.OS;
  let sessionOptions;
  if (platform === 'android') {
    sessionOptions = {
      connectionEventsSuppressed: false,
      ipWhitelist: false,
      iceConfig: {},
      proxyUrl: '',
      useTextureViews: false,
      enableStereoOutput: false,
      androidOnTop: '',
      // 'publisher' || 'subscriber'
      androidZOrder: '',
      // 'mediaOverlay' || 'onTop'
      enableSinglePeerConnection: false,
      sessionMigration: false
    };
  } else {
    sessionOptions = {
      connectionEventsSuppressed: false,
      ipWhitelist: false,
      iceConfig: {},
      proxyUrl: '',
      enableStereoOutput: false,
      enableSinglePeerConnection: false,
      sessionMigration: false
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
      sessionMigration: 'boolean'
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
      sessionMigration: 'boolean'
    }
  };
  (0, _underscore.each)(options, (value, key) => {
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
      (0, _OTError.handleError)(`${key} is not a valid option`);
    }
  });
  if (sessionOptions.iceConfig) {
    const customTurnOptions = sanitizeCustomTurnOptions(sessionOptions.iceConfig);
    (0, _underscore.each)(customTurnOptions, (value, key) => {
      sessionOptions[key] = customTurnOptions[key];
    });
  }
  return sessionOptions;
};
exports.sanitizeSessionOptions = sanitizeSessionOptions;
//# sourceMappingURL=OTSessionHelper.js.map