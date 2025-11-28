"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
var _react = _interopRequireDefault(require("react"));
var _propTypes = _interopRequireDefault(require("prop-types"));
var _OT = require("./OT.js");
var _OTSubscriberNativeComponent = _interopRequireDefault(require("./OTSubscriberNativeComponent"));
var _OTContext = _interopRequireDefault(require("./contexts/OTContext.js"));
var _jsxRuntime = require("react/jsx-runtime");
function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
class OTSubscriberView extends _react.default.Component {
  static defaultProps = {
    subscribeToAudio: true,
    subscribeToVideo: true,
    scaleBehavior: 'fill',
    style: {
      flex: 1
    }
  };
  sessionId = this.context.sessionId;
  eventHandlers = {};
  constructor(props, context) {
    super(props, context);
    this.eventHandlers = props.eventHandlers;
    this.style = props.style;
  }
  getRtcStatsReport() {
    //NOSONAR - this method is exposed externally
    _OT.OT.getSubscriberRtcStatsReport(this.sessionId);
  }
  componentWillUnmount() {
    _OT.OT.removeSubscriber(this.sessionId, this.props.streamId);
  }
  render() {
    const {
      streamId
    } = this.props;
    const subscriberProperties = this.context.subscriberProperties;
    const eventHandlers = this.context.eventHandlers;
    const streamProperties = this.context.streamProperties ? this.context.streamProperties[streamId] : undefined;
    let {
      audioVolume,
      preferredFrameRate,
      preferredResolution,
      subscribeToCaptions
    } = subscriberProperties;
    if (streamProperties) {
      ({
        audioVolume,
        preferredFrameRate,
        preferredResolution,
        subscribeToCaptions
      } = streamProperties);
    }
    const subscribeToVideo = streamProperties?.subscribeToVideo ?? subscriberProperties?.subscribeToVideo ?? true;
    const subscribeToAudio = streamProperties?.subscribeToAudio ?? subscriberProperties?.subscribeToAudio ?? true;
    const scaleBehavior = streamProperties?.scaleBehavior ?? subscriberProperties?.scaleBehavior ?? 'fill';
    const style = streamProperties?.style || this.context.style;
    return /*#__PURE__*/(0, _jsxRuntime.jsx)(_OTSubscriberNativeComponent.default, {
      sessionId: this.sessionId,
      streamId: streamId,
      subscribeToAudio: subscribeToAudio,
      subscribeToVideo: subscribeToVideo,
      scaleBehavior: scaleBehavior,
      subscribeToCaptions: subscribeToCaptions,
      preferredFrameRate: preferredFrameRate,
      preferredResolution: preferredResolution,
      audioVolume: audioVolume,
      onAudioLevel: event => {
        eventHandlers.audioLevel?.(event.nativeEvent);
      },
      onAudioNetworkStats: event => {
        eventHandlers.audioNetworkStats?.(event.nativeEvent);
      },
      onSubscriberConnected: event => {
        eventHandlers.subscriberConnected?.(event.nativeEvent);
      },
      onRtcStatsReport: event => {
        eventHandlers.rtcStatsReport?.(event.nativeEvent);
      },
      onVideoEnabled: event => {
        eventHandlers.videoEnabled?.(event.nativeEvent);
      },
      onVideoNetworkStats: event => {
        eventHandlers.videoNetworkStats?.(event.nativeEvent);
      },
      style: style
    });
  }
}
exports.default = OTSubscriberView;
OTSubscriberView.propTypes = {
  streamId: _propTypes.default.string.isRequired
};
OTSubscriberView.contextType = _OTContext.default;
//# sourceMappingURL=OTSubscriberView.js.map