import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { View, Platform } from 'react-native';
import { isNull } from 'underscore';
import uuid from 'react-native-uuid';
import {
  checkAndroidPermissions,
  OT,
  removeNativeEvents,
  nativeEvents,
  setNativeEvents,
} from './OT';
import {
  sanitizeProperties,
  sanitizePublisherEvents,
} from './helpers/OTPublisherHelper';
import OTPublisherView from './views/OTPublisherView';
import { getOtrnErrorEventHandler } from './helpers/OTHelper';
import { isConnected } from './helpers/OTSessionHelper';
import OTContext from './contexts/OTContext';

class OTPublisher extends Component {
  constructor(props, context) {
    super(props, context);
    this.state = {
      initError: null,
      publisher: null,
      publisherId: uuid.v4(),
    };
    this.initComponent();
  }
  initComponent = () => {
    this.componentEvents = {
      publisherStreamCreated: 'publisherStreamCreated',
      publisherStreamDestroyed: 'publisherStreamDestroyed:',
      sessionConnected:
        Platform.OS === 'android'
          ? 'session:onConnected'
          : 'session:sessionDidConnect',
    };
    this.componentEventsArray = Object.values(this.componentEvents);
    this.otrnEventHandler = getOtrnErrorEventHandler(this.props.eventHandlers);
    this.publisherEvents = sanitizePublisherEvents(
      this.state.publisherId,
      this.props.eventHandlers
    );
    setNativeEvents(this.publisherEvents);
    OT.setJSComponentEvents(this.componentEventsArray);
    this.publisherStreamCreated = nativeEvents.addListener(
      'publisherStreamCreated',
      stream => this.publisherStreamCreatedHandler(stream)
    );
    this.publisherStreamDestroyed = nativeEvents.addListener(
      'publisherStreamDestroyed',
      stream => this.publisherStreamDestroyedHandler(stream)
    );
    if (this.context.sessionId) {
      this.sessionConnected = nativeEvents.addListener(
        `${this.context.sessionId}:${this.componentEvents.sessionConnected}`,
        () => this.sessionConnectedHandler()
      );
    }
  };
  componentDidMount() {
    this.createPublisher();
  }
  componentDidUpdate(previousProps) {
    const useDefault = (value, defaultValue) =>
      value === undefined ? defaultValue : value;
    const shouldUpdate = (key, defaultValue) => {
      const previous = useDefault(previousProps.properties[key], defaultValue);
      const current = useDefault(this.props.properties[key], defaultValue);
      return previous !== current;
    };

    const updatePublisherProperty = (key, defaultValue) => {
      if (shouldUpdate(key, defaultValue)) {
        const value = useDefault(this.props.properties[key], defaultValue);
        if (key === 'cameraPosition') {
          OT.changeCameraPosition(this.state.publisherId, value);
        } else if (key === 'videoContentHint') {
          OT.changeVideoContentHint(this.state.publisherId, value);
        } else {
          OT[key](this.state.publisherId, value);
        }
      }
    };

    updatePublisherProperty('publishAudio', true);
    updatePublisherProperty('publishVideo', true);
    updatePublisherProperty('publishCaptions', false);
    updatePublisherProperty('cameraPosition', 'front');
    updatePublisherProperty('videoContentHint', '');
  }
  componentWillUnmount() {
    OT.destroyPublisher(this.state.publisherId, (error) => {
      if (error) {
        this.otrnEventHandler(error);
      } else {
        this.sessionConnected.remove();
        OT.removeJSComponentEvents(this.componentEventsArray);
        removeNativeEvents(this.publisherEvents);
      }
    });
  }
  sessionConnectedHandler = () => {
    if (isNull(this.state.publisher) && isNull(this.state.initError)) {
      this.publish();
    }
  };
  createPublisher() {
    const publisherProperties = sanitizeProperties(this.props.properties);
    if (Platform.OS === 'android') {
      const { audioTrack, videoTrack, videoSource } = publisherProperties;
      const isScreenSharing = (videoSource === 'screen');
      checkAndroidPermissions(audioTrack, videoTrack, isScreenSharing)
        .then(() => {
          this.initPublisher(publisherProperties);
        })
        .catch((error) => {
          this.otrnEventHandler(error);
        });
    } else {
      this.initPublisher(publisherProperties);
    }
  }
  initPublisher(publisherProperties) {
    OT.initPublisher(
      this.state.publisherId,
      publisherProperties,
      (initError) => {
        if (initError) {
          this.setState({
            initError,
          });
          this.otrnEventHandler(initError);
        } else {
          if (this.context.sessionId) {
            OT.getSessionInfo(this.context.sessionId, (session) => {
              if (
                !isNull(session) &&
                isNull(this.state.publisher) &&
                isConnected(session.connectionStatus)
              ) {
                this.publish();
              }
            });
          }
        }
      }
    );
  }
  publish() {
    OT.publish(
      this.context.sessionId,
      this.state.publisherId,
      (publishError) => {
        if (publishError) {
          this.otrnEventHandler(publishError);
        } else {
          this.setState({
            publisher: true,
          });
        }
      }
    );
  }
  getRtcStatsReport() {
    OT.getRtcStatsReport(this.state.publisherId);
  }

  publisherStreamCreatedHandler = (stream) => {
    if (
      this.props.eventHandlers
      && this.props.eventHandlers.streamCreated
      && stream.publisherId === this.state.publisherId
    ) {
      this.props.eventHandlers.streamCreated(stream);
    }
  }

  publisherStreamDestroyedHandler = (stream) => {
    if (
      this.props.eventHandlers
      && this.props.eventHandlers.streamDestroyed
      && stream.publisherId === this.state.publisherId
    ) {
      this.props.eventHandlers.streamDestroyed(stream);
    }
  }

  setAudioTransformers(audioTransformers) {
    OT.setAudioTransformers(this.state.publisherId, audioTransformers);
  }

  setVideoTransformers(videoTransformers) {
    OT.setVideoTransformers(this.state.publisherId, videoTransformers);
  }

  render() {
    const { publisher, publisherId } = this.state;
    const { sessionId } = this.context;
    if (publisher && publisherId) {
      return (
        <OTPublisherView
          publisherId={publisherId}
          sessionId={sessionId}
          {...this.props}
        />
      );
    }
    return <View />;
  }
}
const viewPropTypes = View.propTypes;
OTPublisher.propTypes = {
  ...viewPropTypes,
  properties: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  eventHandlers: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  getRtcStatsReport: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  setAudioTransformers: PropTypes.func, // eslint-disable-line react/forbid-prop-types
  setVideoTransformers: PropTypes.func, // eslint-disable-line react/forbid-prop-types
};
OTPublisher.defaultProps = {
  properties: {},
  eventHandlers: {},
  getRtcStatsReport: {},
};
OTPublisher.contextType = OTContext;
export default OTPublisher;
