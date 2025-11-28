"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
var _react = _interopRequireDefault(require("react"));
var _reactNative = require("react-native");
var _deprecatedReactNativePropTypes = require("deprecated-react-native-prop-types");
var _propTypes = _interopRequireDefault(require("prop-types"));
var _underscore = require("underscore");
var _reactNativeUuid = _interopRequireDefault(require("react-native-uuid"));
var _OT = require("./OT.js");
var _OTPublisherNativeComponent = _interopRequireDefault(require("./OTPublisherNativeComponent"));
var _OTSessionHelper = require("./helpers/OTSessionHelper.js");
var _OTPublisherHelper = require("./helpers/OTPublisherHelper.js");
var _OTContext = _interopRequireDefault(require("./contexts/OTContext.js"));
var _jsxRuntime = require("react/jsx-runtime");
function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
class OTPublisher extends _react.default.Component {
  eventHandlers = {};
  publisherProperties = {};
  constructor(props) {
    super(props);
    const mergedProperties = {
      ...OTPublisher.defaultProps.properties,
      ...props.properties
    };
    this.state = {
      publisherId: _reactNativeUuid.default.v4(),
      publishVideo: mergedProperties.publishVideo,
      permissionsGranted: _reactNative.Platform.OS === 'ios',
      componentMounted: false,
      publisherProperties: (0, _OTPublisherHelper.sanitizeProperties)(mergedProperties)
    };
    this.eventHandlers = props.eventHandlers;
    this.initComponent(props.eventHandlers);
  }
  componentDidMount() {
    (0, _OTSessionHelper.addEventListener)(this.context.sessionId, 'sessionConnected', this.onSessionConnected);
    this.setState({
      componentMounted: true
    });
  }
  componentDidUpdate() {
    const {
      properties
    } = this.props;
    const sanitizedProperties = (0, _OTPublisherHelper.sanitizeProperties)(properties);
    if (!(0, _underscore.isEqual)(this.state.publisherProperties, sanitizedProperties)) {
      this.setState(prevState => ({
        publisherProperties: sanitizedProperties
      }));
    }
  }
  onSessionConnected = () => {
    if (_reactNative.Platform.OS === 'android') {
      const {
        audioTrack,
        videoTrack,
        videoSource
      } = this.state.publisherProperties;
      const isScreenSharing = videoSource === 'screen';
      (0, _OT.checkAndroidPermissions)(audioTrack, videoTrack, isScreenSharing).then(() => {
        _OT.OT.publish(this.context.sessionId, this.state.publisherId);
        this.setState({
          permissionsGranted: true
        });
      }).catch(error => {
        // this.otrnEventHandler(error);
      });
    } else {
      _OT.OT.publish(this.context.sessionId, this.state.publisherId);
    }
  };
  initComponent = () => {
    this.eventHandlers.streamCreated = this.props.eventHandlers?.streamCreated;
    this.eventHandlers.streamDestroyed = this.props.eventHandlers?.streamDestroyed;
    this.eventHandlers.error = this.props.eventHandlers?.error;
    this.eventHandlers.audioLevel = this.props.eventHandlers?.audioLevel;
    this.eventHandlers.audioNetworkStats = this.props.eventHandlers?.audioNetworkStats;
    this.eventHandlers.rtcStatsReport = this.props.eventHandlers?.rtcStatsReport;
    this.eventHandlers.videoDisabled = this.props.eventHandlers?.videoDisabled;
    this.eventHandlers.videoDisableWarning = this.props.eventHandlers?.videoDisableWarning;
    this.eventHandlers.videoDisableWarningLifted = this.props.eventHandlers?.videoDisableWarningLifted;
    this.eventHandlers.videoEnabled = this.props.eventHandlers?.videoEnabled;
    this.eventHandlers.videoNetworkStats = this.props.eventHandlers?.videoNetworkStats;
    this.publisherProperties = (0, _OTPublisherHelper.sanitizeProperties)(this.props.properties);
    if (_reactNative.Platform.OS === 'android') {
      const {
        audioTrack,
        videoTrack,
        videoSource
      } = this.publisherProperties;
      const isScreenSharing = videoSource === 'screen';
      (0, _OT.checkAndroidPermissions)(audioTrack, videoTrack, isScreenSharing).then(() => {
        if (this.context && (0, _OTSessionHelper.isConnected)(this.context.sessionId)) {
          setTimeout(() => _OT.OT.publish(this.context.sessionId, this.state.publisherId), 0);
        }
        this.setState({
          permissionsGranted: true
        });
      }).catch(error => {
        // this.otrnEventHandler(error);
      });
    } else if (this.context && (0, _OTSessionHelper.isConnected)(this.context.sessionId)) {
      setTimeout(() => _OT.OT.publish(this.context.sessionId, this.state.publisherId), 100);
    }
  };
  getRtcStatsReport() {
    //NOSONAR - this method is exposed externally
    _OT.OT.getPublisherRtcStatsReport(this.context.sessionId, this.state.publisherId);
  }
  componentWillUnmount() {
    _OT.OT.unpublish(this.context.sessionId, this.state.publisherId);
    (0, _OTSessionHelper.removeEventListener)(this.context.sessionId, 'sessionConnected', this.onSessionConnected);
  }
  getPrePermissionViewStyle = props => ({
    backgroundColor: '#000',
    ...this.props.style
  });
  render() {
    return this.state.permissionsGranted && this.state.componentMounted ? /*#__PURE__*/(0, _jsxRuntime.jsx)(_OTPublisherNativeComponent.default, {
      sessionId: this.context.sessionId,
      publisherId: this.state.publisherId,
      onError: event => {
        this.props.eventHandlers?.error?.(event.nativeEvent);
      },
      onStreamCreated: event => {
        (0, _OTSessionHelper.dispatchEvent)(this.context.sessionId, 'publisherStreamCreated', event.nativeEvent);
        this.props.eventHandlers?.streamCreated?.(event.nativeEvent);
      },
      onStreamDestroyed: event => {
        (0, _OTSessionHelper.dispatchEvent)(this.context.sessionId, 'publisherStreamDestroyed', event);
        this.props.eventHandlers?.streamDestroyed?.(event.nativeEvent);
      },
      onAudioLevel: event => {
        this.props.eventHandlers?.audioLevel?.(event.nativeEvent);
      },
      onAudioNetworkStats: event => {
        // TODO - remove workaround for Android stats prop
        const eventData = event.nativeEvent.jsonStats ? JSON.parse(event.nativeEvent.jsonStats) : event.nativeEvent.stats;
        this.props.eventHandlers?.audioNetworkStats?.(eventData);
      },
      onRtcStatsReport: event => {
        this.props.eventHandlers?.rtcStatsReport?.(JSON.parse(event.nativeEvent.jsonStats));
      },
      onVideoDisabled: event => {
        this.props.eventHandlers?.videoDisabled?.(event.nativeEvent);
      },
      onVideoDisableWarning: event => {
        this.props.eventHandlers?.videoDisableWarning?.(event.nativeEvent);
      },
      onVideoDisableWarningLifted: event => {
        this.props.eventHandlers?.videoDisableWarningLifted?.(event.nativeEvent);
      },
      onVideoEnabled: event => {
        this.props.eventHandlers?.videoEnabled?.(event.nativeEvent);
      },
      onVideoNetworkStats: event => {
        // TODO - remove workaround for Android stats prop
        const eventData = event.nativeEvent.jsonStats ? JSON.parse(event.nativeEvent.jsonStats) : event.nativeEvent.stats;
        this.props.eventHandlers?.videoNetworkStats?.(eventData);
      },
      style: this.props.style,
      ...this.state.publisherProperties
    }) : /*#__PURE__*/(0, _jsxRuntime.jsx)(_reactNative.View, {
      style: this.getPrePermissionViewStyle()
    });
  }
}
exports.default = OTPublisher;
OTPublisher.propTypes = {
  eventHandlers: _propTypes.default.object,
  properties: _propTypes.default.object,
  style: _deprecatedReactNativePropTypes.ViewPropTypes.style
};
OTPublisher.defaultProps = {
  eventHandlers: {},
  properties: {
    publishAudio: true,
    publishVideo: true,
    audioBitrate: 40000,
    audioFallback: {
      publisher: false,
      subscriber: true
    },
    audioTrack: true,
    cameraPosition: 'front',
    enableDtx: false,
    frameRate: 30,
    name: '',
    publishCaptions: false,
    scalableScreenshare: false,
    allowAudioCaptureWhileMuted: false,
    resolution: 'MEDIUM',
    videoTrack: true,
    videoSource: 'camera',
    videoContentHint: '',
    maxVideoBitrate: 0,
    videoBitratePreset: 'default',
    scaleBehavior: 'fill'
  },
  style: {
    flex: 1
  }
};
OTPublisher.contextType = _OTContext.default;
//# sourceMappingURL=OTPublisher.js.map