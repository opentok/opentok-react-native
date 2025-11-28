"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
var _react = _interopRequireWildcard(require("react"));
var _reactNative = require("react-native");
var _propTypes = _interopRequireDefault(require("prop-types"));
var _underscore = require("underscore");
var _OT = require("./OT.js");
var _OTSessionHelper = require("./helpers/OTSessionHelper.js");
var _OTSubscriberView = _interopRequireDefault(require("./OTSubscriberView.js"));
var _OTSubscriberHelper = require("./helpers/OTSubscriberHelper.js");
var _OTContext = _interopRequireDefault(require("./contexts/OTContext.js"));
var _jsxRuntime = require("react/jsx-runtime");
function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
function _interopRequireWildcard(e, t) { if ("function" == typeof WeakMap) var r = new WeakMap(), n = new WeakMap(); return (_interopRequireWildcard = function (e, t) { if (!t && e && e.__esModule) return e; var o, i, f = { __proto__: null, default: e }; if (null === e || "object" != typeof e && "function" != typeof e) return f; if (o = t ? n : r) { if (o.has(e)) return o.get(e); o.set(e, f); } for (const t in e) "default" !== t && {}.hasOwnProperty.call(e, t) && ((i = (o = Object.defineProperty) && Object.getOwnPropertyDescriptor(e, t)) && (i.get || i.set) ? o(f, t, i) : f[t] = e[t]); return f; })(e, t); }
class OTSubscriber extends _react.Component {
  sessionId = this.context.sessionId;
  // sessionInfo = this.context.sessionInfo;

  constructor(props, context) {
    super(props, context);
    let initialStreams = (0, _OTSessionHelper.getStreams)(this.context.sessionId);
    let initialPublisherStream = (0, _OTSessionHelper.getPublisherStream)(this.context.sessionId);
    if (props.subscribeToSelf && initialPublisherStream) {
      initialStreams.push(initialPublisherStream);
    }
    (0, _OTSubscriberHelper.sanitizeStreamProperties)(props.streamProperties);
    this.state = {
      streams: initialStreams,
      properties: props.properties,
      streamProperties: props.streamProperties,
      subscribeToSelf: props.subscribeToSelf || false
    };
    // this.otrnEventHandler = getOtrnErrorEventHandler(this.props.eventHandlers);
    this.initComponent();
  }
  initComponent = () => {
    (0, _OTSessionHelper.addEventListener)(this.context.sessionId, 'streamCreated', this.streamCreatedHandler);
    (0, _OTSessionHelper.addEventListener)(this.context.sessionId, 'publisherStreamCreated', this.publisherStreamCreatedHandler);
    (0, _OTSessionHelper.addEventListener)('publisherStreamDestroyed', this.publisherStreamDestroyedHandler);
    (0, _OTSessionHelper.addEventListener)(this.context.sessionId, 'streamDestroyed', this.streamDestroyedHandler);
    (0, _OTSessionHelper.addEventListener)(this.context.sessionId, 'subscriberConnected', this.subscriberConnectedHandler);
  };
  componentDidUpdate() {
    const {
      streamProperties,
      properties
    } = this.props;
    if (!(0, _underscore.isEqual)(this.state.properties, properties)) {
      (0, _OTSubscriberHelper.sanitizeProperties)(properties);
      this.setState(prevState => ({
        properties
      }));
    }
    if (!(0, _underscore.isEqual)(this.state.streamProperties, streamProperties)) {
      (0, _OTSubscriberHelper.sanitizeStreamProperties)(streamProperties);
      this.setState(prevState => ({
        streamProperties
      }));
    }
  }
  publisherStreamCreatedHandler = stream => {
    if (this.props.subscribeToSelf) {
      this.streamCreatedHandler(stream);
    }
  };
  streamCreatedHandler = stream => {
    this.setState(prevState => {
      const modifiedStreams = prevState.streams;
      if (!modifiedStreams.includes(stream.streamId)) {
        modifiedStreams.push(stream.streamId);
      }
      return {
        streams: modifiedStreams
      };
    });
  };
  streamDestroyedHandler = stream => {
    this.setState(prevState => ({
      streams: prevState.streams.filter(item => item !== stream.streamId)
    }));
  };
  subscriberConnectedHandler = event => {
    this.props.eventHandlers?.subscriberConnected?.(event.nativeEvent);
  };
  publisherStreamDestroyedHandler = stream => {
    if (this.state.subscribeToSelf) {
      this.streamDestroyedHandler(stream);
    }
  };
  getRtcStatsReport() {
    _OT.OT.getSubscriberRtcStatsReport(this.context.sessionId);
  }
  componentWillUnmount() {
    (0, _OTSessionHelper.removeEventListener)('streamCreated', this.streamCreatedHandler);
    (0, _OTSessionHelper.removeEventListener)(this.context.sessionId, 'publisherStreamCreated', this.publisherStreamCreatedHandler);
    (0, _OTSessionHelper.removeEventListener)(this.context.sessionId, 'publisherStreamDestroyed', this.publisherStreamDestroyedHandler);
    (0, _OTSessionHelper.removeEventListener)(this.context.sessionId, 'streamDestroyed', this.streamDestroyedHandler);
    (0, _OTSessionHelper.removeEventListener)(this.context.sessionId, 'subscriberConnected', this.subscriberConnectedHandler);
  }
  render() {
    if (!this.props.children) {
      const containerStyle = this.props.containerStyle;
      const childrenWithStreams = this.state.streams.map(streamId => {
        const style = this.state.style;
        return /*#__PURE__*/(0, _jsxRuntime.jsx)(_OTContext.default.Provider, {
          value: {
            sessionId: this.sessionId,
            subscriberProperties: this.state.properties,
            streamProperties: this.state.streamProperties,
            eventHandlers: this.props.eventHandlers,
            style: this.props.style
          },
          children: /*#__PURE__*/(0, _jsxRuntime.jsx)(_OTSubscriberView.default, {
            streamId: streamId,
            style: style,
            ...this.props.properties
          })
        }, streamId);
      });
      return /*#__PURE__*/(0, _jsxRuntime.jsx)(_reactNative.View, {
        style: containerStyle,
        children: childrenWithStreams
      });
    }
    if (this.props.children(this.state.streams)) {
      return this.props.children(this.state.streams).map(elem => /*#__PURE__*/(0, _jsxRuntime.jsx)(_OTContext.default.Provider, {
        value: {
          sessionId: this.sessionId,
          subscriberProperties: this.state.properties,
          streamProperties: this.state.streamProperties,
          style: this.props.style,
          eventHandlers: this.props.eventHandlers
        },
        children: elem
      }, elem.props.streamId));
    }
    return null;
  }
}
exports.default = OTSubscriber;
const viewPropTypes = _reactNative.View.propTypes;
OTSubscriber.propTypes = {
  ...viewPropTypes,
  children: _propTypes.default.func,
  properties: _propTypes.default.object,
  eventHandlers: _propTypes.default.object,
  streamProperties: _propTypes.default.object,
  containerStyle: _propTypes.default.object,
  getRtcStatsReport: _propTypes.default.object,
  subscribeToSelf: _propTypes.default.bool
};
OTSubscriber.defaultProps = {
  properties: {},
  eventHandlers: {},
  streamProperties: {},
  containerStyle: {},
  subscribeToSelf: false,
  getRtcStatsReport: {}
};
OTSubscriber.contextType = _OTContext.default;
//# sourceMappingURL=OTSubscriber.js.map