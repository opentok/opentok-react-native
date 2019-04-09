import { Platform } from 'react-native';
import { reassignEvents } from './OTHelper';
import { handleSignalError, handleError } from '../OTError';
import { each, isNull, isEmpty, isString } from 'underscore';

const sanitizeSessionEvents = (events) => {
  if (typeof events !== 'object') {
    return {};
  }
  const customEvents = {
    ios: {
      streamCreated: 'streamCreated',
      streamDestroyed: 'streamDestroyed',
      sessionConnected: 'sessionDidConnect',
      sessionDisconnected: 'sessionDidDisconnect',
      signal: 'signal',
      connectionCreated: 'connectionCreated',
      connectionDestroyed: 'connectionDestroyed',
      error: 'didFailWithError',
      sessionReconnected: 'sessionDidReconnect',
      sessionReconnecting: 'sessionDidBeginReconnecting',
      archiveStarted: 'archiveStartedWithId',
      archiveStopped: 'archiveStoppedWithId',
      streamPropertyChanged: 'streamPropertyChanged',
    },
    android: {
      streamCreated: 'onStreamReceived',
      streamDestroyed: 'onStreamDropped',
      sessionConnected: 'onConnected',
      sessionDisconnected: 'onDisconnected',
      signal: 'onSignalReceived',
      connectionCreated: 'onConnectionCreated',
      connectionDestroyed: 'onConnectionDestroyed',
      error: 'onError',
      sessionReconnected: 'onReconnected',
      sessionReconnecting: 'onReconnecting',
      archiveStarted: 'onArchiveStarted',
      archiveStopped: 'onArchiveStopped',
      streamPropertyChanged: 'onStreamPropertyChanged',
    },
  };
  return reassignEvents('session', customEvents, events);
};


const sanitizeSessionOptions = (options) => {
  const platform = Platform.OS;
  let sessionOptions;

  if (platform === 'android') {
    sessionOptions = {
      isCamera2Capable: false,
      connectionEventsSuppressed: false,
      useTextureViews: false
    }
  } else {
    sessionOptions = {
      connectionEventsSuppressed: false
    }
  }

  if (typeof options !== 'object') {
    return sessionOptions;
  }
  
  const validSessionOptions = {
    ios: {
      connectionEventsSuppressed: 'connectionEventsSuppressed',
    },
    android: {
      connectionEventsSuppressed: 'connectionEventsSuppressed',
      useTextureViews: 'useTextureViews',
      isCamera2Capable: 'isCamera2Capable',
    },
  };


  each(options, (sessionOptionValue, sessionOption) => {
    if (validSessionOptions[platform][sessionOption] !== undefined) {
      sessionOptions[validSessionOptions[platform][sessionOption]] = sessionOptionValue;
    } else {
      handleError(`${sessionOption} is not a valid option`);
    }
  });

  return sessionOptions;
};

const validateString = value => (isString(value) ? value : '');

const sanitizeSignalData = (signal) => {
  if (typeof signal !== 'object') {
    return {
      signal: {
        type: '',
        data: '',
      },
      errorHandler: handleSignalError,
    };
  }
  return {
    signal: {
      type: validateString(signal.type),
      data: validateString(signal.data),
    },
    errorHandler: typeof signal.errorHandler !== 'function' ? handleSignalError : signal.errorHandler,
  };
};

const sanitizeCredentials = (credentials) => {
  const _credentials = {};
  each(credentials, (value, key) => {
    if(!isString(value) || isEmpty(value) || isNull(value)) {
      handleError(`Please add the ${key}`);
    } else {
      _credentials[key] = value;
    }
  });
  return _credentials;
};

const getConnectionStatus = (connectionStatus) => {
  switch(connectionStatus) {
    case 0:
      return "not connected";
    case 1:
      return "connected";
    case 2:
      return "connecting";
    case 3:
      return "reconnecting";
    case 4:
      return "disconnecting";
    case 5:
      return "failed";
  }
};

const isConnected = (connectionStatus) => (getConnectionStatus(connectionStatus) === 'connected');

export {
  sanitizeSessionEvents,
  sanitizeSessionOptions,
  sanitizeSignalData,
  sanitizeCredentials,
  getConnectionStatus,
  isConnected,
};
