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

export {
  sanitizeSessionEvents,
  sanitizeSignalData,
  sanitizeCredentials,
};
