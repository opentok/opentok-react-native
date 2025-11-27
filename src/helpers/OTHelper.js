import { Platform } from 'react-native';
import { handleError } from '../OTError';
import axios from 'axios';

const sanitizeBooleanProperty = (property) =>
  property || property === undefined ? true : property;

const getOtrnErrorEventHandler = (events) => {
  let otrnEventHandler = (event) => {
    handleError(event);
  };
  if (typeof events !== 'object') {
    return otrnEventHandler;
  } else if (events.otrnError) {
    otrnEventHandler = events.otrnError;
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

export { sanitizeBooleanProperty, logOT, getOtrnErrorEventHandler };
