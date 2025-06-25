import React, { Component } from 'react';
import { View } from 'react-native';
import PropTypes from 'prop-types';
import { each, isEqual } from 'underscore';
import { OT } from './OT';
import {
  addEventListener,
  removeEventListener,
  getStreams,
  getPublisherStream,
} from './helpers/OTSessionHelper';
import OTSubscriberView from './OTSubscriberView';

import {
  sanitizeProperties,
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
    let initialStreams = getStreams();
    let initialPublisherStream = getPublisherStream();
    if (props.subscribeToSelf && initialPublisherStream) {
      initialStreams.push(initialPublisherStream);
    }
    each(props.streamProperties, (individualStreamProperties, streamId) => {
      const {
        subscribeToAudio,
        subscribeToVideo,
        subscribeToCaptions,
        preferredResolution,
        preferredFrameRate,
        audioVolume,
      } = individualStreamProperties;
      if (subscribeToAudio !== undefined) {
        sanitizeBooleanProperty(subscribeToAudio);
      }
      if (subscribeToVideo !== undefined) {
        sanitizeBooleanProperty(subscribeToVideo);
      }
      if (subscribeToCaptions !== undefined) {
        sanitizeBooleanProperty(subscribeToCaptions);
      }
      if (preferredResolution !== undefined) {
        sanitizeResolution(preferredResolution);
      }
      if (preferredFrameRate !== undefined) {
        sanitizeFrameRate(preferredFrameRate);
      }
      if (audioVolume !== undefined) {
        sanitizeAudioVolume(audioVolume);
      }
    });
    this.state = {
      streams: initialStreams,
      properties: props.properties,
      streamProperties: props.streamProperties,
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
    const { streamProperties, properties } = this.props;
    sanitizeProperties(properties);
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
          sanitizeBooleanProperty(subscribeToAudio);
        }
        if (subscribeToVideo !== undefined) {
          sanitizeBooleanProperty(subscribeToVideo);
        }
        if (subscribeToCaptions !== undefined) {
          sanitizeBooleanProperty(subscribeToCaptions);
        }
        if (preferredResolution !== undefined) {
          sanitizeResolution(preferredResolution);
        }
        if (preferredFrameRate !== undefined) {
          sanitizeFrameRate(preferredFrameRate);
        }
        if (audioVolume !== undefined) {
          sanitizeAudioVolume(audioVolume);
        }
      });
      this.setState({
        properties,
        streamProperties,
      });
    }
  }

  publisherStreamCreatedHandler = (stream) => {
    if (this.props.subscribeToSelf) {
      this.streamCreatedHandler(stream);
    }
  };

  streamCreatedHandler = (stream) => {
    this.setState((prevState) => {
      const modifiedStreams = prevState.streams;
      if (!modifiedStreams.includes(stream.streamId)) {
        modifiedStreams.push(stream.streamId);
      }
      return { streams: modifiedStreams };
    });
  };
  streamDestroyedHandler = (stream) => {
    this.setState((prevState) => ({
      streams: prevState.streams.filter((item) => item !== stream.streamId),
    }));
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

  componentWillUnmount() {
    removeEventListener('streamCreated', this.streamCreatedHandler);
    removeEventListener(
      'publisherStreamCreated',
      this.publisherStreamCreatedHandler
    );
    removeEventListener(
      'publisherStreamDestroyed',
      this.publisherStreamDestroyedHandler
    );
    removeEventListener('streamDestroyed', this.streamDestroyedHandler);
    removeEventListener('subscriberConnected', this.subscriberConnectedHandler);
  }

  render() {
    if (!this.props.children) {
      const containerStyle = this.props.containerStyle;
      const childrenWithStreams = this.state.streams.map((streamId) => {
        const style = this.state.style;
        return (
          <OTContext.Provider
            value={{
              sessionId: this.sessionId,
              subscriberProperties: this.state.properties,
              streamProperties: this.state.streamProperties,
              eventHandlers: this.props.eventHandlers,
              style: this.props.style,
            }}
            key={streamId}
          >
            <OTSubscriberView
              streamId={streamId}
              style={style}
              {...this.props.properties}
            />
          </OTContext.Provider>
        );
      });
      return <View style={containerStyle}>{childrenWithStreams}</View>;
    }
    if (this.props.children(this.state.streams)) {
      return this.props.children(this.state.streams).map((elem) => (
        <OTContext.Provider
          value={{
            sessionId: this.sessionId,
            subscriberProperties: this.state.properties,
            streamProperties: this.state.streamProperties,
            style: this.props.style,
            eventHandlers: this.props.eventHandlers,
          }}
          key={elem.props.streamId}
        >
          {elem}
        </OTContext.Provider>
      ));
    }
    return null;
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
  getRtcStatsReport: PropTypes.object,
  subscribeToSelf: PropTypes.bool,
};

OTSubscriber.defaultProps = {
  properties: {},
  eventHandlers: {},
  streamProperties: {},
  containerStyle: {},
  subscribeToSelf: false,
  getRtcStatsReport: {},
};

OTSubscriber.contextType = OTContext;
