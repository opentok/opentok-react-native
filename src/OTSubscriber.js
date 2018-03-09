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
    this.streamCreated = nativeEvents.addListener(
      this.componentEvents.streamCreated,
      (stream) => {
        const subscriberProperties = sanitizeProperties(this.props.properties);
        OT.subscribeToStream(stream.streamId, subscriberProperties, (error) => {
          if (error) {
            handleError(error);
          } else {
            const oldStreams = this.state.streams;
            const streams = [...oldStreams, stream.streamId];
            this.setState({
              streams,
            });
          }
        });
      },
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
  render() {
    if (this.state.streams.length < 1) {
      return <View />;
    }
    const childrenWithStreams = this.state.streams.map(streamId =>
      <OTSubscriberView key={streamId} streamId={streamId} style={this.props.style} />);
    return <View>{ childrenWithStreams }</View>;
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
