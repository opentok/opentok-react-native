import React from 'react';
import { Platform } from 'react-native';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import uuid from 'react-native-uuid';
import { checkAndroidPermissions, OT } from './OT';
import OTPublisherViewNative from './OTPublisherViewNativeComponent';
import { addEventListener, isConnected } from './helpers/OTSessionHelper';
import { sanitizeProperties } from './helpers/OTPublisherHelper';

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
            setTimeout(() => OT.publish(this.state.publisherId), 10);
          }
        })
        .catch((error) => {
          // this.otrnEventHandler(error);
        });
    } else {
      if (isConnected) {
        //  OT.publish(this.state.publisherId);
      }
    }
  };

  getRtcStatsReport() {
    //NOSONAR - this method is exposed externally
    OT.getPublisherRtcStatsReport();
  }

  dispatchEvent(type, event) {
    if (this.props.eventHandlers && this.props.eventHandlers[type]) {
      this.props.eventHandlers[type](event);
    }
  }

  render() {
    return (
      <OTPublisherViewNative
        sessionId={this.props.sessionId}
        publisherId={this.state.publisherId}
        {...this.publisherProperties}
        onError={(event) => {
          this.dispatchEvent('error', event);
        }}
        onStreamCreated={(event) => {
          this.dispatchEvent('streamCreated', event);
        }}
        onStreamDestroyed={(event) => {
          this.dispatchEvent('streamDestroyed', event);
        }}
        onAudioLevel={(event) => {
          this.dispatchEvent('audioLevel', event);
        }}
        onAudioNetworkStats={(event) => {
          this.dispatchEvent('audioNetworkStats', event);
        }}
        onRtcStatsReport={(event) => {
          this.dispatchEvent('rtcStatsReport', event);
        }}
        onVideoDisabled={(event) => {
          this.dispatchEvent('videoDisabled', event);
        }}
        onVideoDisableWarning={(event) => {
          this.dispatchEvent('videoDisableWarning', event);
        }}
        onVideoDisableWarningLifted={(event) => {
          this.dispatchEvent('videoDisableWarningLifted', event);
        }}
        onVideoEnabled={(event) => {
          this.dispatchEvent('videoEnabled', event);
        }}
        onVideoNetworkStats={(event) => {
          this.dispatchEvent('videoNetworkStats', event);
        }}
        style={this.props.style}
        {...this.props.properties}
      />
    );
  }
}

OTPublisher.propTypes = {
  sessionId: PropTypes.string.isRequired,
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
