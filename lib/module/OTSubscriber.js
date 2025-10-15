"use strict";

import React, { Component } from 'react';
import { View } from 'react-native';
import PropTypes from 'prop-types';
import { isEqual } from 'underscore';
import { OT } from "./OT.js";
import { addEventListener, removeEventListener, getStreams, getPublisherStream } from "./helpers/OTSessionHelper.js";
import OTSubscriberView from "./OTSubscriberView.js";
import { sanitizeProperties, sanitizeStreamProperties } from "./helpers/OTSubscriberHelper.js";
import OTContext from "./contexts/OTContext.js";
import { jsx as _jsx } from "react/jsx-runtime";
export default class OTSubscriber extends Component {
  sessionId = this.context.sessionId;
  // sessionInfo = this.context.sessionInfo;

  constructor(props, context) {
    super(props, context);
    let initialStreams = getStreams(this.context.sessionId);
    let initialPublisherStream = getPublisherStream(this.context.sessionId);
    if (props.subscribeToSelf && initialPublisherStream) {
      initialStreams.push(initialPublisherStream);
    }
    sanitizeStreamProperties(props.streamProperties);
    this.state = {
      streams: initialStreams,
      properties: props.properties,
      streamProperties: props.streamProperties,
      subscribeToSelf: props.subscribeToSelf || false
    };
    // this.otrnEventHandler = getOtrnErrorEventHandler(this.props.eventHandlers);
    this.initComponent();
  }
  initComponent = () => {
    addEventListener(this.context.sessionId, 'streamCreated', this.streamCreatedHandler);
    addEventListener(this.context.sessionId, 'publisherStreamCreated', this.publisherStreamCreatedHandler);
    addEventListener('publisherStreamDestroyed', this.publisherStreamDestroyedHandler);
    addEventListener(this.context.sessionId, 'streamDestroyed', this.streamDestroyedHandler);
    addEventListener(this.context.sessionId, 'subscriberConnected', this.subscriberConnectedHandler);
  };
  componentDidUpdate() {
    const {
      streamProperties,
      properties
    } = this.props;
    if (!isEqual(this.state.properties, properties)) {
      sanitizeProperties(properties);
      this.setState(prevState => ({
        properties
      }));
    }
    if (!isEqual(this.state.streamProperties, streamProperties)) {
      sanitizeStreamProperties(streamProperties);
      this.setState(prevState => ({
        streamProperties
      }));
    }
  }
  publisherStreamCreatedHandler = stream => {
    if (this.props.subscribeToSelf) {
      this.streamCreatedHandler(stream);
    }
  };
  streamCreatedHandler = stream => {
    this.setState(prevState => {
      const modifiedStreams = prevState.streams;
      if (!modifiedStreams.includes(stream.streamId)) {
        modifiedStreams.push(stream.streamId);
      }
      return {
        streams: modifiedStreams
      };
    });
  };
  streamDestroyedHandler = stream => {
    this.setState(prevState => ({
      streams: prevState.streams.filter(item => item !== stream.streamId)
    }));
  };
  subscriberConnectedHandler = event => {
    this.props.eventHandlers?.subscriberConnected?.(event.nativeEvent);
  };
  publisherStreamDestroyedHandler = stream => {
    if (this.state.subscribeToSelf) {
      this.streamDestroyedHandler(stream);
    }
  };
  getRtcStatsReport() {
    OT.getSubscriberRtcStatsReport(this.context.sessionId);
  }
  componentWillUnmount() {
    removeEventListener('streamCreated', this.streamCreatedHandler);
    removeEventListener(this.context.sessionId, 'publisherStreamCreated', this.publisherStreamCreatedHandler);
    removeEventListener(this.context.sessionId, 'publisherStreamDestroyed', this.publisherStreamDestroyedHandler);
    removeEventListener(this.context.sessionId, 'streamDestroyed', this.streamDestroyedHandler);
    removeEventListener(this.context.sessionId, 'subscriberConnected', this.subscriberConnectedHandler);
  }
  render() {
    if (!this.props.children) {
      const containerStyle = this.props.containerStyle;
      const childrenWithStreams = this.state.streams.map(streamId => {
        const style = this.state.style;
        return /*#__PURE__*/_jsx(OTContext.Provider, {
          value: {
            sessionId: this.sessionId,
            subscriberProperties: this.state.properties,
            streamProperties: this.state.streamProperties,
            eventHandlers: this.props.eventHandlers,
            style: this.props.style
          },
          children: /*#__PURE__*/_jsx(OTSubscriberView, {
            streamId: streamId,
            style: style,
            ...this.props.properties
          })
        }, streamId);
      });
      return /*#__PURE__*/_jsx(View, {
        style: containerStyle,
        children: childrenWithStreams
      });
    }
    if (this.props.children(this.state.streams)) {
      return this.props.children(this.state.streams).map(elem => /*#__PURE__*/_jsx(OTContext.Provider, {
        value: {
          sessionId: this.sessionId,
          subscriberProperties: this.state.properties,
          streamProperties: this.state.streamProperties,
          style: this.props.style,
          eventHandlers: this.props.eventHandlers
        },
        children: elem
      }, elem.props.streamId));
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
  subscribeToSelf: PropTypes.bool
};
OTSubscriber.defaultProps = {
  properties: {},
  eventHandlers: {},
  streamProperties: {},
  containerStyle: {},
  subscribeToSelf: false,
  getRtcStatsReport: {}
};
OTSubscriber.contextType = OTContext;
//# sourceMappingURL=OTSubscriber.js.map