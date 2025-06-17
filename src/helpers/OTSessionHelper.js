import { Platform } from 'react-native';

import { each, isString, isBoolean, isObject, isArray } from 'underscore';

import { handleError } from '../OTError';

const validateString = (value) => (isString(value) ? value : '');

const validateBoolean = (value) => (isBoolean(value) ? value : false);

const validateObject = (value) => (isObject(value) ? value : {});

const validateArray = (value) => (isArray(value) ? value : []);

const eventHandlers = {};

let connected = false;

const setIsConnected = (value) => {
  connected = value;
};

const isConnected = () => connected;

const dispatchEvent = (type, event) => {
  const listeners = eventHandlers[type];
  if (listeners) {
    listeners.forEach((listener) => {
      listener(event);
    });
  }
};

const addEventListener = (type, listener) => {
  if (!eventHandlers[type]) {
    eventHandlers[type] = [listener];
  } else {
    eventHandlers[type].push(listener);
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
  isConnected,
  setIsConnected,
  dispatchEvent,
  addEventListener,
  sanitizeSessionOptions,
};
