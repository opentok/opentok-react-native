import React from 'react';
import { Platform } from 'react-native';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import uuid from 'react-native-uuid';
import {
  checkAndroidPermissions,
  OT,
} from './OT';
import OTPublisherViewNative from './OTPublisherViewNativeComponent';
import { addEventListener, isConnected } from './helpers/OTSessionHelper';

export default class OTPublisherView extends React.Component {
  eventHandlers = {};

  constructor(props) {
    super(props);
    this.eventHandlers = props.eventHandlers;
    this.initComponent(props.eventHandlers);
    this.state = {
      publisherId: uuid.v4(),
    };
  }

  onSessionConnected = () => {
    OT.publish(this.state.publisherId);
  }

  initComponent = () => {
    addEventListener('sessionConnected', this.onSessionConnected)
    this.eventHandlers.streamCreated =
      this.props.eventHandlers?.streamCreated;
    this.eventHandlers.streamDestroyed =
      this.props.eventHandlers?.streamDestroyed;
    this.eventHandlers.error =
      this.props.eventHandlers?.error;
    if (Platform.OS === 'android') {
      // const publisherProperties = sanitizeProperties(this.props.properties);
      const publisherProperties = { audioTrack: true, videoTrack: true, videoSource: 'camera' };
      const { audioTrack, videoTrack, videoSource } = publisherProperties;
      const isScreenSharing = (videoSource === 'screen');
      checkAndroidPermissions(audioTrack, videoTrack, isScreenSharing)
        .then(() => {
          if (isConnected()) {
            setTimeout( () => OT.publish(this.state.publisherId), 10);
          };
        })
        .catch((error) => {
          // this.otrnEventHandler(error);
        });
    } else {
      if (isConnected) {
        OT.publish(this.state.publisherId);
      };
    }
  };

  render() {
    const { style, sessionId, streamId, publishAudio, publishVideo } =
      this.props;
    return (
      <OTPublisherViewNative
        sessionId={sessionId}
        publisherId={this.state.publisherId}
        publishAudio={publishAudio}
        publishVideo={publishVideo}
        onError={(event) => {
          this.eventHandlers.error && this.eventHandlers.error(event.nativeEvent);
        }}
        onStreamCreated={(event) => {
          this.eventHandlers.streamCreated && this.eventHandlers.streamCreated(event.nativeEvent);
        }}
        style={style}
      />
    );
  }
}

OTPublisherView.propTypes = {
  sessionId: PropTypes.string.isRequired,
  eventHandlers: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  publishAudio: PropTypes.bool,
  publishVideo: PropTypes.bool,
  style: ViewPropTypes.style,
};

OTPublisherView.defaultProps = {
  eventHandlers: {},
  properties: {
    publishAudio: true,
    publishVideo: true,  
  },
  style: {
    flex: 1,
  },
};
