import { reassignEvents } from './OTHelper';
import { handleSignalError } from '../OTError';

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

const isString = value => (typeof value !== 'string' ? '' : value);

const sanitizeSignalData = (signal) => {
  if (typeof signal !== 'object') {
    return {
      type: '',
      data: '',
      errorHandler: handleSignalError,
    };
  }
  return {
    type: signal.type ? isString(signal.type) : '',
    data: signal.data ? isString(signal.data) : '',
    errorHandler: typeof signal.errorHandler !== 'function' ? handleSignalError : signal.errorHandler,
  };
};

export {
  sanitizeSessionEvents,
  sanitizeSignalData,
};
