import React from 'react';
import { Platform, View } from 'react-native';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import { isEqual } from 'underscore';
import uuid from 'react-native-uuid';
import { checkAndroidPermissions, OT } from './OT';
import OTRNPublisher from './OTPublisherNativeComponent';
import {
  addEventListener,
  removeEventListener,
  dispatchEvent,
  isConnected,
} from './helpers/OTSessionHelper';
import { sanitizeProperties } from './helpers/OTPublisherHelper';
import OTContext from './contexts/OTContext';

export default class OTPublisher extends React.Component {
  eventHandlers = {};
  publisherProperties = {};

  constructor(props) {
    super(props);
    const mergedProperties = {
      ...OTPublisher.defaultProps.properties,
      ...props.properties,
    };
    this.state = {
      publisherId: uuid.v4(),
      publishVideo: mergedProperties.publishVideo,
      permissionsGranted: Platform.OS === 'ios',
      publisherProperties: sanitizeProperties(mergedProperties),
    };
    this.eventHandlers = props.eventHandlers;
    this.initComponent(props.eventHandlers);
  }

  componentDidUpdate() {
    const { properties } = this.props;
    const sanitizedProperties = sanitizeProperties(properties);
    if (!isEqual(this.state.publisherProperties, sanitizedProperties)) {
      this.setState((prevState) => ({
        publisherProperties: sanitizedProperties,
      }));
    }
  }

  onSessionConnected = () => {
    if (Platform.OS === 'android') {
      const { audioTrack, videoTrack, videoSource } =
        this.state.publisherProperties;
      const isScreenSharing = videoSource === 'screen';
      checkAndroidPermissions(audioTrack, videoTrack, isScreenSharing)
        .then(() => {
          OT.publish(this.context.sessionId, this.state.publisherId);
          this.setState({
            permissionsGranted: true,
          });
        })
        .catch((error) => {
          // this.otrnEventHandler(error);
        });
    } else {
      OT.publish(this.context.sessionId, this.state.publisherId);
    }
  };

  initComponent = () => {
    addEventListener('sessionConnected', this.onSessionConnected);
    this.eventHandlers.streamCreated = this.props.eventHandlers?.streamCreated;
    this.eventHandlers.streamDestroyed =
      this.props.eventHandlers?.streamDestroyed;
    this.eventHandlers.error = this.props.eventHandlers?.error;
    this.eventHandlers.audioLevel = this.props.eventHandlers?.audioLevel;
    this.eventHandlers.audioNetworkStats =
      this.props.eventHandlers?.audioNetworkStats;
    this.eventHandlers.rtcStatsReport =
      this.props.eventHandlers?.rtcStatsReport;
    this.eventHandlers.videoDisabled = this.props.eventHandlers?.videoDisabled;
    this.eventHandlers.videoDisableWarning =
      this.props.eventHandlers?.videoDisableWarning;
    this.eventHandlers.videoDisableWarningLifted =
      this.props.eventHandlers?.videoDisableWarningLifted;
    this.eventHandlers.videoEnabled = this.props.eventHandlers?.videoEnabled;
    this.eventHandlers.videoNetworkStats =
      this.props.eventHandlers?.videoNetworkStats;
    this.publisherProperties = sanitizeProperties(this.props.properties);

    if (Platform.OS === 'android') {
      const { audioTrack, videoTrack, videoSource } = this.publisherProperties;
      const isScreenSharing = videoSource === 'screen';
      checkAndroidPermissions(audioTrack, videoTrack, isScreenSharing)
        .then(() => {
          if (isConnected()) {
            setTimeout(() => OT.publish(this.state.publisherId), 0);
          }
          this.setState({
            permissionsGranted: true,
          });
        })
        .catch((error) => {
          // this.otrnEventHandler(error);
        });
    } else if (isConnected()) {
      setTimeout(() => OT.publish(this.state.publisherId), 100);
    }
  };

  getRtcStatsReport() {
    //NOSONAR - this method is exposed externally
    OT.getPublisherRtcStatsReport(this.state.publisherId);
  }

  componentWillUnmount() {
    OT.unpublish(sessionId, this.state.publisherId);
    removeEventListener('sessionConnected', this.onSessionConnected);
  }

  getPrePermissionViewStyle = (props) => ({
    backgroundColor: '#000',
    ...this.props.style,
  });

  render() {
    return this.state.permissionsGranted ? (
      <OTRNPublisher
        sessionId={this.context.sessionId}
        publisherId={this.state.publisherId}
        onError={(event) => {
          this.props.eventHandlers?.error?.(event.nativeEvent);
        }}
        onStreamCreated={(event) => {
          dispatchEvent('publisherStreamCreated', event.nativeEvent);
          this.props.eventHandlers?.streamCreated?.(event.nativeEvent);
        }}
        onStreamDestroyed={(event) => {
          dispatchEvent('publisherStreamDestroyed', event);
          this.props.eventHandlers?.streamDestroyed?.(event.nativeEvent);
        }}
        onAudioLevel={(event) => {
          this.props.eventHandlers?.audioLevel?.(event.nativeEvent);
        }}
        onAudioNetworkStats={(event) => {
          // TODO - remove workaround for Android stats prop
          const eventData = event.nativeEvent.jsonStats
            ? JSON.parse(event.nativeEvent.jsonStats)
            : event.nativeEvent.stats;
          this.props.eventHandlers?.audioNetworkStats?.(eventData);
        }}
        onRtcStatsReport={(event) => {
          this.props.eventHandlers?.rtcStatsReport?.(
            JSON.parse(event.nativeEvent.jsonStats)
          );
        }}
        onVideoDisabled={(event) => {
          this.props.eventHandlers?.videoDisabled?.(event.nativeEvent);
        }}
        onVideoDisableWarning={(event) => {
          this.props.eventHandlers?.videoDisableWarning?.(event.nativeEvent);
        }}
        onVideoDisableWarningLifted={(event) => {
          this.props.eventHandlers?.videoDisableWarningLifted?.(
            event.nativeEvent
          );
        }}
        onVideoEnabled={(event) => {
          this.props.eventHandlers?.videoEnabled?.(event.nativeEvent);
        }}
        onVideoNetworkStats={(event) => {
          // TODO - remove workaround for Android stats prop
          const eventData = event.nativeEvent.jsonStats
            ? JSON.parse(event.nativeEvent.jsonStats)
            : event.nativeEvent.stats;
          this.props.eventHandlers?.videoNetworkStats?.(eventData);
        }}
        style={this.props.style}
        {...this.state.publisherProperties}
      />
    ) : (
      <View style={this.getPrePermissionViewStyle()} />
    );
  }
}

OTPublisher.propTypes = {
  eventHandlers: PropTypes.object,
  properties: PropTypes.object,
  style: ViewPropTypes.style,
};

OTPublisher.defaultProps = {
  eventHandlers: {},
  properties: {
    publishAudio: true,
    publishVideo: true,
    audioBitrate: 40000,
    audioFallback: {
      publisher: false,
      subscriber: true,
    },
    audioTrack: true,
    cameraPosition: 'front',
    enableDtx: false,
    frameRate: 30,
    name: '',
    publishCaptions: false,
    scalableScreenshare: false,
    resolution: 'MEDIUM',
    videoTrack: true,
    videoSource: 'camera',
    videoContentHint: '',
  },
  style: {
    flex: 1,
  },
};

OTPublisher.contextType = OTContext;
