"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.sanitizeBooleanProperty = exports.logOT = exports.getOtrnErrorEventHandler = void 0;
var _reactNative = require("react-native");
var _OTError = require("../OTError.js");
var _axios = _interopRequireDefault(require("axios"));
function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
const sanitizeBooleanProperty = property => property || property === undefined ? true : property;
exports.sanitizeBooleanProperty = sanitizeBooleanProperty;
const getOtrnErrorEventHandler = events => {
  let otrnEventHandler = event => {
    (0, _OTError.handleError)(event);
  };
  if (typeof events !== 'object') {
    return otrnEventHandler;
  } else if (events.otrnError) {
    otrnEventHandler = events.otrnError;
  }
  return otrnEventHandler;
};
exports.getOtrnErrorEventHandler = getOtrnErrorEventHandler;
const getLog = (apiKey, sessionId, action, connectionId) => {
  const body = {
    payload: {
      platform: _reactNative.Platform.OS,
      otrn_version: require('../../../package.json').version,
      platform_version: _reactNative.Platform.Version
    },
    payload_type: 'info',
    action,
    partner_id: apiKey,
    session_id: sessionId,
    source: require('../../../package.json').repository.url
  };
  if (connectionId) {
    body.connectionId = connectionId;
  }
  return body;
};
const logRequest = (body, proxyUrl) => {
  const hlgUrl = 'hlg.tokbox.com/prod/logging/ClientEvent';
  const url = proxyUrl ? `${proxyUrl}/${hlgUrl}` : `https://${hlgUrl}`;
  (0, _axios.default)({
    url,
    method: 'post',
    data: body
  }).then(() => {
    // response complete
  }).catch(() => {
    (0, _OTError.handleError)('logging');
  });
};
const logOT = ({
  apiKey,
  sessionId,
  action,
  connectionId,
  proxyUrl
}) => {
  logRequest(getLog(apiKey, sessionId, action, connectionId), proxyUrl);
};
exports.logOT = logOT;
//# sourceMappingURL=OTHelper.js.map