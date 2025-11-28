"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
var _react = _interopRequireWildcard(require("react"));
var _reactNative = require("react-native");
var _deprecatedReactNativePropTypes = require("deprecated-react-native-prop-types");
var _propTypes = _interopRequireDefault(require("prop-types"));
var _OT = require("./OT.js");
var _OTSessionHelper = require("./helpers/OTSessionHelper.js");
var _OTError = require("./OTError.js");
var _OTHelper = require("./helpers/OTHelper.js");
var _OTContext = _interopRequireDefault(require("./contexts/OTContext.js"));
var _jsxRuntime = require("react/jsx-runtime");
function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
function _interopRequireWildcard(e, t) { if ("function" == typeof WeakMap) var r = new WeakMap(), n = new WeakMap(); return (_interopRequireWildcard = function (e, t) { if (!t && e && e.__esModule) return e; var o, i, f = { __proto__: null, default: e }; if (null === e || "object" != typeof e && "function" != typeof e) return f; if (o = t ? n : r) { if (o.has(e)) return o.get(e); o.set(e, f); } for (const t in e) "default" !== t && {}.hasOwnProperty.call(e, t) && ((i = (o = Object.defineProperty) && Object.getOwnPropertyDescriptor(e, t)) && (i.get || i.set) ? o(f, t, i) : f[t] = e[t]); return f; })(e, t); }
class OTSession extends _react.Component {
  eventHandlers = {};
  async initSession(apiKey, sessionId, token) {
    if (apiKey && sessionId && token) {
      (0, _OTHelper.logOT)({
        apiKey,
        sessionId,
        action: 'rn_initialize',
        proxyUrl: this.props.options?.proxyUrl
      });
    } else {
      (0, _OTError.handleError)('Please check your OpenTok credentials.');
    }
    _OT.OT.onSessionConnected(event => {
      if (event.sessionId !== sessionId) return;
      this.connectionId = event.connectionId;
      (0, _OTSessionHelper.setIsConnected)(sessionId, true);
      this.eventHandlers?.sessionConnected?.(event);
      (0, _OTSessionHelper.dispatchEvent)(sessionId, 'sessionConnected', event);
      if (Object.keys(this.props.signal).length > 0) {
        this.signal(this.props.signal);
      }
    });
    _OT.OT.initSession(apiKey, sessionId, (0, _OTSessionHelper.sanitizeSessionOptions)(this.props.options));
    if (this.props.encryptionSecret) {
      this.setEncryptionSecret(this.props.encryptionSecret);
    }
    _OT.OT.onStreamCreated(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.streamCreated?.(event);
      if (event.connectionId !== this.connectionId) {
        (0, _OTSessionHelper.addStream)(sessionId, event.streamId);
      }
      (0, _OTSessionHelper.dispatchEvent)(sessionId, 'streamCreated', event);
    });
    _OT.OT.onStreamDestroyed(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.streamDestroyed?.(event);
      (0, _OTSessionHelper.removeStream)(sessionId, event.streamId);
      (0, _OTSessionHelper.dispatchEvent)(sessionId, 'streamDestroyed', event);
    });
    _OT.OT.onSignalReceived(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.signal?.(event);
    });
    _OT.OT.onSessionError(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.error?.(event);
    });
    _OT.OT.onConnectionCreated(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.connectionCreated?.(event);
    });
    _OT.OT.onConnectionDestroyed(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.connectionDestroyed?.(event);
    });
    _OT.OT.onArchiveStarted(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.archiveStarted?.(event);
    });
    _OT.OT.onArchiveStopped(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.archiveStopped?.(event);
    });
    _OT.OT.onMuteForced(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.muteForced?.(event);
    });
    _OT.OT.onSessionReconnecting(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.sessionReconnecting?.(event);
    });
    _OT.OT.onSessionReconnected(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.sessionReconnected?.(event);
    });
    _OT.OT.onStreamPropertyChanged(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.streamPropertyChanged?.(event);
    });
    _OT.OT.connect(sessionId, token);
  }
  constructor(props) {
    super(props);
    this.eventHandlers = props.eventHandlers;
    this.initComponent(props.eventHandlers);
  }
  initComponent = () => {
    this.initSession(this.props.apiKey, this.props.sessionId, this.props.token);
  };
  reportIssue() {
    return _OT.OT.reportIssue(this.props.sessionId);
  }
  getCapabilities() {
    return _OT.OT.getCapabilities(this.props.sessionId);
  }
  forceMuteAll(excludedStreamIds) {
    return _OT.OT.forceMuteAll(this.props.sessionId, excludedStreamIds || []);
  }
  forceMuteStream(streamId) {
    return _OT.OT.forceMuteStream(this.props.sessionId, streamId);
  }
  disableForceMute() {
    return _OT.OT.disableForceMute(this.props.sessionId);
  }
  signal(signalObj) {
    _OT.OT.sendSignal(this.props.sessionId, signalObj.type || '', signalObj.data || '', signalObj.to || '');
  }
  setEncryptionSecret(value) {
    _OT.OT.setEncryptionSecret(this.props.sessionId, value);
  }
  forceDisconnect(connectionId) {
    return _OT.OT.forceDisconnect(this.props.sessionId, connectionId);
  }
  disconnectSession(sessionId) {
    _OT.OT.disconnect(sessionId);
  }
  componentDidUpdate(previousProps) {
    const shouldUseDefault = (value, defaultValue) => value === undefined ? defaultValue : value;
    const shouldUpdate = (key, defaultValue) => {
      const previous = shouldUseDefault(previousProps[key], defaultValue);
      const current = shouldUseDefault(this.props[key], defaultValue);
      return previous !== current;
    };
    const updateSessionProperty = (key, defaultValue) => {
      if (shouldUpdate(key, defaultValue)) {
        const value = shouldUseDefault(this.props[key], defaultValue);
        if (key === 'signal') {
          this.signal(value);
        }
        if (key === 'encryptionSecret') {
          this.setEncryptionSecret(value);
        }
      }
    };
    updateSessionProperty('signal', {});
    updateSessionProperty('encryptionSecret', undefined);
  }
  componentWillUnmount() {
    this.disconnectSession(this.props.sessionId);
    (0, _OTSessionHelper.clearStreams)(this.props.sessionId);
  }
  render() {
    const {
      style,
      children,
      sessionId,
      apiKey,
      token
    } = this.props;
    if (children && sessionId && apiKey && token) {
      return /*#__PURE__*/(0, _jsxRuntime.jsx)(_OTContext.default.Provider, {
        value: {
          sessionId,
          connectionId: this.connectionId
        },
        children: /*#__PURE__*/(0, _jsxRuntime.jsx)(_reactNative.View, {
          style: style,
          children: children
        })
      });
    }
    return /*#__PURE__*/(0, _jsxRuntime.jsx)(_reactNative.View, {});
  }
}
exports.default = OTSession;
OTSession.propTypes = {
  apiKey: _propTypes.default.string.isRequired,
  sessionId: _propTypes.default.string.isRequired,
  token: _propTypes.default.string.isRequired,
  children: _propTypes.default.oneOfType([_propTypes.default.element, _propTypes.default.arrayOf(_propTypes.default.element)]),
  style: _deprecatedReactNativePropTypes.ViewPropTypes.style,
  eventHandlers: _propTypes.default.object,
  options: _propTypes.default.object,
  signal: _propTypes.default.object,
  encryptionSecret: _propTypes.default.string
};
OTSession.defaultProps = {
  eventHandlers: {},
  options: {},
  signal: {},
  style: {
    flex: 1
  }
};
//# sourceMappingURL=OTSession.js.map