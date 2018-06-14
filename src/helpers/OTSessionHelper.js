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

const validateString = value => (isString(value) ? value : '');

const sanitizeSignalData = (signal) => {
  if (typeof signal !== 'object') {
    return {
      type: '',
      data: '',
      errorHandler: handleSignalError,
    };
  }
  return {
    type: validateString(signal.type),
    data: validateString(signal.data),
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
  sanitizeSignalData,
  sanitizeCredentials,
  getConnectionStatus,
  isConnected,
};
