import { Platform } from 'react-native';
import { each } from 'underscore';
import axios from 'axios';
import { handleError } from '../OTError';

const otrnPackage = require('../../package.json');

const reassignEvents = (type, customEvents, events, publisherId) => {
  const newEvents = {};
  const preface = `${type}:`;
  const platform = Platform.OS;
  each(events, (eventHandler, eventType) => {
    if (customEvents[platform][eventType] !== undefined && publisherId !== undefined) {
      newEvents[`${publisherId}:${preface}${customEvents[platform][eventType]}`] = eventHandler;
    } else if (customEvents[platform][eventType] !== undefined) {
      newEvents[`${preface}${customEvents[platform][eventType]}`] = eventHandler;
    } else if (events.otrnError) {
      // ignore otrnError event because it's for the js layer
    } else {
      handleError(`${eventType} is not a supported event`);
    }
  });
  return newEvents;
};

const sanitizeBooleanProperty = property => (property || property === undefined ? true : property);

const getOtrnErrorEventHandler = (events) => {
  let otrnEventHandler = (event) => {
    handleError(event);
  };
  if (typeof events !== 'object') {
    return otrnEventHandler;
  }
  if (events.otrnError) {
    otrnEventHandler = events.otrnError;
  }
  return otrnEventHandler;
};

const getLog = (apiKey, sessionId, action, connectionId) => {
  const body = {
    payload: {
      platform: Platform.OS,
      otrn_version: otrnPackage.version,
      platform_version: Platform.Version,
    },
    payload_type: 'info',
    action,
    partner_id: apiKey,
    session_id: sessionId,
    source: otrnPackage.repository.url,
  };
  if (connectionId) {
    body.connectionId = connectionId;
  }
  return body;
};

const logRequest = (body) => {
  axios({
    url: 'https://hlg.tokbox.com/prod/logging/ClientEvent',
    method: 'post',
    data: JSON.stringify(body),
  })
    .then(() => {
      // response complete
    })
    .catch(() => {
      handleError('logging');
    });
};

const logOT = (apiKey, sessionId, action, connectionId) => {
  logRequest(getLog(apiKey, sessionId, action, connectionId));
};

export {
  sanitizeBooleanProperty,
  reassignEvents,
  logOT,
  getOtrnErrorEventHandler,
};
