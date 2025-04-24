import React from 'react';
import { Platform } from 'react-native';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import uuid from 'react-native-uuid';
import { checkAndroidPermissions, OT } from './OT';
import OTPublisherViewNative from './OTPublisherViewNativeComponent';
import {
  addEventListener,
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
    };
    this.eventHandlers = props.eventHandlers;
    this.publisherProperties = sanitizeProperties(mergedProperties);
    this.initComponent(props.eventHandlers);
  }

  onSessionConnected = () => {
    OT.publish(this.state.publisherId);
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
    OT.getPublisherRtcStatsReport();
  }

  render() {
    return (
      <OTPublisherViewNative
        sessionId={this.context.sessionId}
        publisherId={this.state.publisherId}
        {...this.publisherProperties}
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
          this.props.eventHandlers?.audioNetworkStats?.(
            JSON.parse(event.nativeEvent.json)
          );
        }}
        onRtcStatsReport={(event) => {
          this.props.eventHandlers?.rtcStatsReport?.(
            JSON.parse(event.nativeEvent.json)
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
          this.props.eventHandlers?.videoNetworkStats?.(
            JSON.parse(event.nativeEvent.json)
          );
        }}
        style={this.props.style}
        {...this.props.properties}
      />
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
