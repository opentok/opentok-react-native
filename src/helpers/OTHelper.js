import { Platform } from 'react-native';
import { handleError } from '../OTError';

const libraryVersion = require('../../package.json').version;
const _ = require('underscore');

const reassignEvents = (type, customEvents, events) => {
  const newEvents = {};
  const preface = `${type}:`;
  const platform = Platform.OS;
  _.each(events, (eventHandler, eventType) => {
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
      otrn_version: libraryVersion,
      platform_version: Platform.Version,
    },
    action: 'rn_initialize',
    payload_type: 'info',
    partner_id: apiKey,
    session_id: sessionId,
    source: 'https://github.com/opentok/OpenTokReactNative',
  };
  fetch('https://hlg.tokbox.com/prod/logging/ClientEvent', {
    body: JSON.stringify(body),
    method: 'post',
  })
    .then(() => {
      // initial response
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
