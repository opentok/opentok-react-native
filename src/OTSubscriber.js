import React, { Component } from 'react';
import { View, Platform } from 'react-native';
import PropTypes from 'prop-types';
import { isNull, isUndefined, each, isEqual, isEmpty } from 'underscore';
import { OT, nativeEvents, setNativeEvents, removeNativeEvents } from './OT';
import OTSubscriberView from './views/OTSubscriberView';
import { sanitizeSubscriberEvents, sanitizeProperties, sanitizeFrameRate, sanitizeResolution } from './helpers/OTSubscriberHelper';
import { getOtrnErrorEventHandler, sanitizeBooleanProperty } from './helpers/OTHelper';
import OTContext from './contexts/OTContext';

export default class OTSubscriber extends Component {
  constructor(props, context) {
    super(props, context);
    this.state = {
      streams: [],
      subscribeToSelf: props.subscribeToSelf || false
    };
    this.componentEvents = {
      streamDestroyed: Platform.OS === 'android' ? 'session:onStreamDropped' : 'session:streamDestroyed',
      streamCreated: Platform.OS === 'android' ? 'session:onStreamReceived' : 'session:streamCreated',
    };
    this.componentEventsArray = Object.values(this.componentEvents);
    this.otrnEventHandler = getOtrnErrorEventHandler(this.props.eventHandlers);
    this.initComponent();
  }
  initComponent = () => {
    const { eventHandlers } = this.props;
    const { sessionId } = this.context;
    if (sessionId) {
      this.streamCreated = nativeEvents.addListener(`${sessionId}:${this.componentEvents.streamCreated}`,
        stream => this.streamCreatedHandler(stream));
      this.streamDestroyed = nativeEvents.addListener(`${sessionId}:${this.componentEvents.streamDestroyed}`,
        stream => this.streamDestroyedHandler(stream));
      const subscriberEvents = sanitizeSubscriberEvents(eventHandlers);
      OT.setJSComponentEvents(this.componentEventsArray);
      setNativeEvents(subscriberEvents);
    }
  }
  componentDidUpdate() {
    const { streamProperties } = this.props;
    if (!isEqual(this.state.streamProperties, streamProperties)) {
      each(streamProperties, (individualStreamProperties, streamId) => {
        const { subscribeToAudio, subscribeToVideo, preferredResolution, preferredFrameRate } = individualStreamProperties;
        if (subscribeToAudio !== undefined) {
          OT.subscribeToAudio(streamId, sanitizeBooleanProperty(subscribeToAudio));
        }
        if (subscribeToVideo !== undefined) {
          OT.subscribeToVideo(streamId, sanitizeBooleanProperty(subscribeToVideo));
        }
        if (preferredResolution !== undefined) {
          OT.setPreferredResolution(streamId, sanitizeResolution(preferredResolution));
        }
        if (preferredFrameRate !== undefined) {
          OT.setPreferredFrameRate(streamId, sanitizeFrameRate(preferredFrameRate));
        }
      });
      this.setState({ streamProperties });
    }
  }
  componentWillUnmount() {
    this.streamCreated.remove();
    this.streamDestroyed.remove();
    OT.removeJSComponentEvents(this.componentEventsArray);
    const events = sanitizeSubscriberEvents(this.props.eventHandlers);
    removeNativeEvents(events);
  }
  streamCreatedHandler = (stream) => {
    const { subscribeToSelf } = this.state;
    const { streamProperties, properties } = this.props;
    const { sessionId, sessionInfo } = this.context;
    const subscriberProperties = isNull(streamProperties[stream.streamId]) ?
      sanitizeProperties(properties) : sanitizeProperties(streamProperties[stream.streamId]);
    // Subscribe to streams. If subscribeToSelf is true, subscribe also to his own stream
    const sessionInfoConnectionId = sessionInfo && sessionInfo.connection ? sessionInfo.connection.connectionId : null;
    if (subscribeToSelf || (sessionInfoConnectionId !== stream.connectionId)) {
      OT.subscribeToStream(stream.streamId, sessionId, subscriberProperties, (error) => {
        if (error) {
          this.otrnEventHandler(error);
        } else {
          this.setState({
            streams: [...this.state.streams, stream.streamId],
          });
        }
      });
    }
  }
  streamDestroyedHandler = (stream) => {
    OT.removeSubscriber(stream.streamId, (error) => {
      if (error) {
        this.otrnEventHandler(error);
      } else {
        const indexOfStream = this.state.streams.indexOf(stream.streamId);
        const newState = this.state.streams.slice();
        newState.splice(indexOfStream, 1);
        this.setState({
          streams: newState,
        });
      }
    });
  }
  render() {
    if (!this.props.children) {
      const containerStyle = this.props.containerStyle;
      const childrenWithStreams = this.state.streams.map((streamId) => {
        const streamProperties = this.props.streamProperties[streamId];
        const style = isEmpty(streamProperties) ? this.props.style : (isUndefined(streamProperties.style) || isNull(streamProperties.style)) ? this.props.style : streamProperties.style;
        return <OTSubscriberView key={streamId} streamId={streamId} style={style} />
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
  properties: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  eventHandlers: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  streamProperties: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  containerStyle: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  subscribeToSelf: PropTypes.bool
};

OTSubscriber.defaultProps = {
  properties: {},
  eventHandlers: {},
  streamProperties: {},
  containerStyle: {},
  subscribeToSelf: false
};

OTSubscriber.contextType = OTContext;
