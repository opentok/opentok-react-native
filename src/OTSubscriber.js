import React, { Component } from 'react';
import { View, Platform } from 'react-native';
import PropTypes from 'prop-types';
import { OT, nativeEvents, setNativeEvents, removeNativeEvents } from './OT';
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
    this.streamCreatedHandler = this.streamCreatedHandler.bind(this);
  }
  componentWillMount() {
    const subscriberProperties = sanitizeProperties(this.props.properties);
    this.streamCreated = nativeEvents.addListener(this.componentEvents.streamCreated, stream => this.streamCreatedHandler(stream, subscriberProperties));
    this.streamDestroyed = nativeEvents.addListener(this.componentEvents.streamDestroyed, stream => this.streamDestroyedHandler(stream));
    const subscriberEvents = sanitizeSubscriberEvents(this.props.eventHandlers);
    OT.setJSComponentEvents(this.componentEventsArray);
    setNativeEvents(subscriberEvents);
  }
  componentWillUnmount() {
    this.streamCreated.remove();
    this.streamDestroyed.remove();
    OT.removeJSComponentEvents(this.componentEventsArray);
    const events = sanitizeSubscriberEvents(this.props.eventHandlers);
    removeNativeEvents(events);
  }
  componentDidUpdate(previousProps) {
    const useDefault = (value, defaultValue) => (value === undefined ? defaultValue : value);
    const shouldUpdate = (key, defaultValue) => {
      const previous = useDefault(previousProps.properties[key], defaultValue);
      const current = useDefault(this.props.properties[key], defaultValue);
      return previous !== current;
    };

    const updateStreamProperty = (key, defaultValue) => {
      if (shouldUpdate(key, defaultValue)) {
        const value = useDefault(this.props.properties[key], defaultValue);
        this.state.streams.forEach((stream) => {
          OT[key](stream, value);
        });
      }
    };

    updateStreamProperty('subscribeToAudio', true);
    updateStreamProperty('subscribeToVideo', true);
  }
  streamCreatedHandler = (stream, subscriberProperties) => {
    OT.subscribeToStream(stream.streamId, subscriberProperties, (error) => {
      if (error) {
        handleError(error);
      } else {

        const subscriberProperties2 = sanitizeProperties(this.props.properties);

        // check if followed properties have changed
        const useDefault = (value, defaultValue) => (value === undefined ? defaultValue : value);
        const shouldUpdate = (key, defaultValue) => {
          const previous = useDefault(subscriberProperties[key], defaultValue);
          const current = useDefault(subscriberProperties2[key], defaultValue);
          return previous !== current;
        };

        const updateStreamProperty = (key, defaultValue) => {
          if (shouldUpdate(key, defaultValue)) {
            const value = useDefault(subscriberProperties2[key], defaultValue);
            OT[key](stream.streamId, value);
          }
        };
        updateStreamProperty('subscribeToAudio', true);
        updateStreamProperty('subscribeToVideo', true);


        this.setState({
          streams: [...this.state.streams, stream.streamId],
        });
      }
    });
  }
  streamDestroyedHandler = (stream) => {
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
  }
  render() {
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
