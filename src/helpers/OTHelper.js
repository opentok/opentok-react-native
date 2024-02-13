import { Platform } from 'react-native';
import { handleError } from '../OTError';
import { each } from 'underscore';
import axios from 'axios';

const reassignEvents = (type, customEvents, events, eventKey) => {
  const newEvents = {};
  const preface = `${type}:`;
  const platform = Platform.OS;

  each(events, (eventHandler, eventType) => {
    if (customEvents[platform][eventType] !== undefined && eventKey !== undefined) {
      newEvents[`${eventKey}:${preface}${customEvents[platform][eventType]}`] = eventHandler;
    } else if (customEvents[platform][eventType] !== undefined) {
      newEvents[`${preface}${customEvents[platform][eventType]}`] = eventHandler;
    } else if (events['otrnError']) {
      // ignore otrnError event because it's for the js layer
    } else {
      handleError(`${eventType} is not a supported event`);
    }
  });

  // Set a default handler
  each(customEvents[platform], (event) => {
    if (eventKey !== undefined && !newEvents[`${eventKey}:${preface}${event}`]) {
      newEvents[`${eventKey}:${preface}${event}`] = () => { };
    }
  });

  return newEvents;
};

const sanitizeBooleanProperty = property => (property || property === undefined ? true : property);

const getOtrnErrorEventHandler = (events) => {
  let otrnEventHandler = event => {
    handleError(event);
  }
  if (typeof events !== 'object') {
    return otrnEventHandler;
  } else if (events['otrnError']) {
    otrnEventHandler = events['otrnError'];
  }
  return otrnEventHandler;
};

const getLog = (apiKey, sessionId, action, connectionId) => {
  const body = {
    payload: {
      platform: Platform.OS,
      otrn_version: require('../../package.json').version,
      platform_version: Platform.Version,
    },
    payload_type: 'info',
    action,
    partner_id: apiKey,
    session_id: sessionId,
    source: require('../../package.json').repository.url,
  };
  if (connectionId) {
    body.connectionId = connectionId;
  }
  return body;
};

const logRequest = (body, proxyUrl) => {
  const hlgUrl = 'hlg.tokbox.com/prod/logging/ClientEvent';
  const url = proxyUrl ? `${proxyUrl}/${hlgUrl}` : `https://${hlgUrl}`;
  axios({
    url,
    method: 'post',
    data: body,
  })
    .then(() => {
      // response complete
    })
    .catch(() => {
      handleError('logging');
    });
};

const logOT = ({ apiKey, sessionId, action, connectionId, proxyUrl }) => {
  logRequest(getLog(apiKey, sessionId, action, connectionId), proxyUrl);
};

export {
  sanitizeBooleanProperty,
  reassignEvents,
  logOT,
  getOtrnErrorEventHandler,
};
