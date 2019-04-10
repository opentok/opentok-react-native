import React, { Component } from 'react';
import { View, Platform } from 'react-native';
import PropTypes from 'prop-types';
import {
  isNull, isUndefined, each, isEqual, isEmpty,
} from 'underscore';
import {
  OT, nativeEvents, setNativeEvents, removeNativeEvents,
} from './OT';
import OTSubscriberView from './views/OTSubscriberView';
import { sanitizeSubscriberEvents, sanitizeProperties } from './helpers/OTSubscriberHelper';
import { getOtrnErrorEventHandler } from './helpers/OTHelper';

export default class OTSubscriber extends Component {
  constructor(props) {
    super(props);
    this.state = {
      streams: [],
    };
    this.componentEvents = {
      streamDestroyed: Platform.OS === 'android' ? 'session:onStreamDropped' : 'session:streamDestroyed',
      streamCreated: Platform.OS === 'android' ? 'session:onStreamReceived' : 'session:streamCreated',
    };
    this.componentEventsArray = Object.values(this.componentEvents);
    const { eventHandlers } = this.props;
    this.eventHandlers = eventHandlers;
    this.otrnEventHandler = getOtrnErrorEventHandler(this.eventHandlers);
  }

  componentWillMount() {
    this.streamCreated = nativeEvents.addListener(
      this.componentEvents.streamCreated,
      stream => this.streamCreatedHandler(stream),
    );
    this.streamDestroyed = nativeEvents.addListener(
      this.componentEvents.streamDestroyed,
      stream => this.streamDestroyedHandler(stream),
    );
    const subscriberEvents = sanitizeSubscriberEvents(this.eventHandlers);
    OT.setJSComponentEvents(this.componentEventsArray);
    setNativeEvents(subscriberEvents);
  }

  componentDidUpdate() {
    const { streamProperties } = this.props;
    if (!isEqual(this.state.streamProperties, streamProperties)) {
      each(streamProperties, (individualStreamProperties, streamId) => {
        const { subscribeToAudio, subscribeToVideo } = individualStreamProperties;
        OT.subscribeToAudio(streamId, subscribeToAudio);
        OT.subscribeToVideo(streamId, subscribeToVideo);
      });
      this.setState({ streamProperties });
    }
  }

  componentWillUnmount() {
    this.streamCreated.remove();
    this.streamDestroyed.remove();
    OT.removeJSComponentEvents(this.componentEventsArray);
    const events = sanitizeSubscriberEvents(this.eventHandlers);
    removeNativeEvents(events);
  }

  streamCreatedHandler = (stream) => {
    const { streamId } = stream;
    const { streamProperties, properties } = this.props;
    const subscriberProperties = isNull(streamProperties[streamId])
      ? sanitizeProperties(properties) : sanitizeProperties(streamProperties[streamId]);
    OT.subscribeToStream(streamId, subscriberProperties, (error) => {
      if (error) {
        this.otrnEventHandler(error);
      } else {
        this.setState(state => ({
          streams: [...state.streams, streamId],
        }));
      }
    });
  }

  streamDestroyedHandler = (stream) => {
    const { streamId } = stream;
    OT.removeSubscriber(streamId, (error) => {
      if (error) {
        this.otrnEventHandler(error);
      } else {
        const { streams } = this.state;
        const indexOfStream = streams.indexOf(streamId);
        const newState = streams.slice();
        newState.splice(indexOfStream, 1);
        this.setState({
          streams: newState,
        });
      }
    });
  }

  render() {
    const { containerStyle, streamProperties, style } = this.props;
    const { streams } = this.state;
    const childrenWithStreams = streams.map((streamId) => {
      const individualStreamProperties = streamProperties[streamId];
      const filteredStyle = isEmpty(individualStreamProperties)
        ? style
        : (
          isUndefined(individualStreamProperties.style) || isNull(individualStreamProperties.style)
        )
          ? style : individualStreamProperties.style;
      return <OTSubscriberView key={streamId} streamId={streamId} style={filteredStyle} />;
    });
    return <View style={containerStyle}>{ childrenWithStreams }</View>;
  }
}

const viewPropTypes = View.propTypes;
OTSubscriber.propTypes = {
  ...viewPropTypes,
  properties: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  eventHandlers: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  streamProperties: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  containerStyle: PropTypes.object, // eslint-disable-line react/forbid-prop-types
};

OTSubscriber.defaultProps = {
  properties: {},
  eventHandlers: {},
  streamProperties: {},
  containerStyle: {},
};
