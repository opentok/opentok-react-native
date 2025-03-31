import React, { Component } from 'react';
import { View } from 'react-native';
import PropTypes from 'prop-types';
// import { isNull, isUndefined, each, isEqual, isEmpty } from 'underscore';
import { each, isEqual } from 'underscore';
import { OT } from './OT';
import { addEventListener } from './helpers/OTSessionHelper';
import OTSubscriberView from './OTSubscriberView';
import {
  // sanitizeSubscriberEvents,
  // sanitizeProperties,
  sanitizeFrameRate,
  sanitizeResolution,
  sanitizeAudioVolume,
} from './helpers/OTSubscriberHelper';
import {
  // getOtrnErrorEventHandler,
  sanitizeBooleanProperty,
} from './helpers/OTHelper';
import OTContext from './contexts/OTContext';

export default class OTSubscriber extends Component {
  sessionId = this.context.sessionId;
  // sessionInfo = this.context.sessionInfo;

  constructor(props, context) {
    super(props, context);
    this.state = {
      streams: [],
      subscribeToSelf: props.subscribeToSelf || false,
    };
    // this.otrnEventHandler = getOtrnErrorEventHandler(this.props.eventHandlers);
    this.initComponent();
  }

  initComponent = () => {
    addEventListener('streamCreated', this.streamCreatedHandler);
    addEventListener(
      'publisherStreamCreated',
      this.publisherStreamCreatedHandler
    );
    addEventListener(
      'publisherStreamDestroyed',
      this.publisherStreamDestroyedHandler
    );
    addEventListener('streamDestroyed', this.streamDestroyedHandler);
    addEventListener('subscriberConnected', this.subscriberConnectedHandler);
  };
  componentDidUpdate() {
    const { streamProperties } = this.props;
    if (!isEqual(this.state.streamProperties, streamProperties)) {
      each(streamProperties, (individualStreamProperties, streamId) => {
        const {
          subscribeToAudio,
          subscribeToVideo,
          subscribeToCaptions,
          preferredResolution,
          preferredFrameRate,
          audioVolume,
        } = individualStreamProperties;
        if (subscribeToAudio !== undefined) {
          OT.subscribeToAudio(
            streamId,
            sanitizeBooleanProperty(subscribeToAudio)
          );
        }
        if (subscribeToVideo !== undefined) {
          OT.subscribeToVideo(
            streamId,
            sanitizeBooleanProperty(subscribeToVideo)
          );
        }
        if (subscribeToCaptions !== undefined) {
          OT.subscribeToCaptions(
            streamId,
            sanitizeBooleanProperty(subscribeToCaptions)
          );
        }
        if (preferredResolution !== undefined) {
          OT.setPreferredResolution(
            streamId,
            sanitizeResolution(preferredResolution)
          );
        }
        if (preferredFrameRate !== undefined) {
          OT.setPreferredFrameRate(
            streamId,
            sanitizeFrameRate(preferredFrameRate)
          );
        }
        if (audioVolume !== undefined) {
          OT.setAudioVolume(streamId, sanitizeAudioVolume(audioVolume));
        }
      });
      this.setState({ streamProperties });
    }
  }
  publisherStreamCreatedHandler = (stream) => {
    if (this.props.subscribeToSelf) {
      this.streamCreatedHandler(stream);
    }
  };
  streamCreatedHandler = (stream) => {
    /*
    const { subscribeToSelf, streamProperties, properties } = this.props;
    const subscriberProperties = streamProperties[stream.streamId]
      ? sanitizeProperties(streamProperties[stream.streamId])
      : sanitizeProperties(properties);
    */
    this.setState((prevState) => ({
      streams: [...prevState.streams, stream.streamId],
    }));
  };
  streamDestroyedHandler = (stream) => {
    this.setState((prevState) => {
      const indexOfStream = prevState.streams.indexOf(stream.streamId);
      const newState = prevState.streams.splice(indexOfStream, 1);
      return newState;
    });
    /* TODO
    OT.removeSubscriber(stream.streamId, (error) => {
      if (error) {
        this.otrnEventHandler(error);
      }
    });
    */
  };

  subscriberConnectedHandler = (event) => {
    this.props.eventHandlers?.subscriberConnected?.(event.nativeEvent);
  };

  publisherStreamDestroyedHandler = (stream) => {
    if (this.state.subscribeToSelf) {
      this.streamDestroyedHandler(stream);
    }
  };
  getRtcStatsReport() {
    OT.getSubscriberRtcStatsReport();
  }
  render() {
    if (!this.props.children) {
      const containerStyle = this.props.containerStyle;
      const childrenWithStreams = this.state.streams.map((streamId) => {
        /*
        const streamProperties = this.props.streamProperties[streamId];
        const style = isEmpty(streamProperties)
          ? this.props.style
          : isUndefined(streamProperties.style) ||
              isNull(streamProperties.style)
            ? this.props.style
            : streamProperties.style;
        */
        const style = this.props.style;
        return (
          <OTSubscriberView
            key={streamId}
            streamId={streamId}
            sessionId={this.sessionId}
            style={style}
            {...this.props.properties}
          />
        );
      });
      return <View style={containerStyle}>{childrenWithStreams}</View>;
    }
    return this.props.children(this.state.streams) || null;
  }
}

const viewPropTypes = View.propTypes;
OTSubscriber.propTypes = {
  ...viewPropTypes,
  children: PropTypes.func,
  properties: PropTypes.object,
  eventHandlers: PropTypes.object,
  streamProperties: PropTypes.object,
  containerStyle: PropTypes.object,
  // getRtcStatsReport: PropTypes.object,
  subscribeToSelf: PropTypes.bool,
};

OTSubscriber.defaultProps = {
  properties: {},
  eventHandlers: {},
  streamProperties: {},
  containerStyle: {},
  subscribeToSelf: false,
  // getRtcStatsReport: {},
  // subscribeToCaptions: false,
};

OTSubscriber.contextType = OTContext;
