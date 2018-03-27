import React, { Component } from 'react';
import { View, Platform } from 'react-native';
import PropTypes from 'prop-types';
import { OT, nativeEvents, setNativeEvents } from './OT';
import OTSubscriberView from './views/OTSubscriberView';
import { handleError } from './OTError';
import { sanitizeSubscriberEvents, sanitizeProperties } from './helpers/OTSubscriberHelper';

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
  }

  componentWillMount() {
    const subscriberEvents = sanitizeSubscriberEvents(this.props.eventHandlers);
    setNativeEvents(subscriberEvents);
    this.setEventListeners();
  }

  componentWillUnmount() {
    this.streamCreated.remove();
    this.streamDestroyed.remove();
    OT.removeJSComponentEvents(this.componentEventsArray);
  }

  setEventListeners() {
    OT.setJSComponentEvents(this.componentEventsArray);
    const subscriberProperties = sanitizeProperties(this.props.properties);

    this.props.streams.map(streamId => {
      this.onStreamSubscribe(streamId, subscriberProperties) // subscribe to events that we have already
    })

    this.streamCreated = nativeEvents.addListener(
      this.componentEvents.streamCreated,
      stream => this.onStreamSubscribe(stream.streamId, subscriberProperties)
    );
  
    this.streamDestroyed = nativeEvents.addListener(
      this.componentEvents.streamDestroyed,
      (stream) => {
        OT.removeSubscriber(stream.streamId, (error) => {
          if (error) {
            handleError(error);
          } else {
            const indexOfStream = this.state.streams.indexOf(stream.streamId);
            const newState = this.state.streams.slice();
            newState.splice(indexOfStream, 1);
            this.setState({
              streams: newState,
            });
          }
        });
      },
    );
  }

  onStreamSubscribe = (streamId, subscriberProperties) => {
    OT.subscribeToStream(streamId, subscriberProperties, (error) => {
      if (error) {
        handleError(error);
      } else {
        const oldStreams = this.state.streams;
        const streams = [...oldStreams, streamId];
        this.setState({
          streams,
        });
      }
    });
  }

  render() {
    if (this.state.streams.length < 1) {
      return <View />;
    }
    const childrenWithStreams = this.state.streams.map(streamId => (
      <OTSubscriberView key={streamId} streamId={streamId} style={this.props.style} {...this.props} />
    ));
    return <View>{childrenWithStreams}</View>;
  }
}

const viewPropTypes = View.propTypes;
OTSubscriber.propTypes = {
  ...viewPropTypes,
  properties: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  eventHandlers: PropTypes.object, // eslint-disable-line react/forbid-prop-types
};

OTSubscriber.defaultProps = {
  properties: {},
  eventHandlers: {},
};
