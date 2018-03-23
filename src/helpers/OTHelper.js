import { Platform } from 'react-native';
import { handleError } from '../OTError';
import { each } from 'underscore';
import axios from 'axios';

const reassignEvents = (type, customEvents, events) => {
  const newEvents = {};
  const preface = `${type}:`;
  const platform = Platform.OS;
  each(events, (eventHandler, eventType) => {
    if (customEvents[platform][eventType] !== undefined) {
      newEvents[`${preface}${customEvents[platform][eventType]}`] = eventHandler;
    } else {
      handleError(`${eventType} is not a supported event`);
    }
  });
  return newEvents;
};

const sanitizeBooleanProperty = property => (property || property === undefined ? true : property);

const logOT = (apiKey, sessionId) => {
  const body = {
    payload: {
      platform: Platform.OS,
      otrn_version: require('../../package.json').version,
      platform_version: Platform.Version,
    },
    action: 'rn_initialize',
    payload_type: 'info',
    partner_id: apiKey,
    session_id: sessionId,
    source: require('../../package.json').repository.url,
  };
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

export {
  sanitizeBooleanProperty,
  reassignEvents,
  logOT,
};
