import React, { Component, Children, cloneElement } from 'react';
import { View, Platform, ViewPropTypes } from 'react-native';
import PropTypes from 'prop-types';
import { createSession, disconnectSession, setNativeEvents, nativeEvents, OT } from './OT';
import { sanitizeSessionEvents, sanitizeSignalData } from './helpers/OTSessionHelper';
import { logOT } from './helpers/OTHelper';
import { handleError } from './OTError';

export default class OTSession extends Component {
  componentEvents = {
    streamDestroyed: Platform.OS === 'android' ? 'session:onStreamDropped' : 'session:streamDestroyed',
    streamCreated: Platform.OS === 'android' ? 'session:onStreamReceived' : 'session:streamCreated',
  }

  state = {
    streams: [],
    isConnected: false,
    sessionInfo: null,
  }

  componentWillMount() {
    const sessionEvents = sanitizeSessionEvents(this.props.eventHandlers);
    setNativeEvents(sessionEvents);

    nativeEvents.addListener(this.componentEvents.streamCreated, this.onStreamCreated)
    nativeEvents.addListener(this.componentEvents.streamDestroyed, this.onStreamDestroyed)
    
    this.createSession();
    logOT(this.props.apiKey, this.props.sessionId);
  }

  componentDidUpdate(previousProps) {
    const useDefault = (value, defaultValue) => (value === undefined ? defaultValue : value);
    const shouldUpdate = (key, defaultValue) => {
      const previous = useDefault(previousProps[key], defaultValue);
      const current = useDefault(this.props[key], defaultValue);
      return previous !== current;
    };

    const updateSessionProperty = (key, defaultValue) => {
      if (shouldUpdate(key, defaultValue)) {
        const value = useDefault(this.props[key], defaultValue);
        const signalData = sanitizeSignalData(value);
        OT.sendSignal(signalData, signalData.errorHandler);
      }
    };

    updateSessionProperty('signal', {});
  }

  componentWillUnmount() {
    nativeEvents.removeListener(this.componentEvents.streamCreated)
    nativeEvents.removeListener(this.componentEvents.streamDestroyed)
    this.disconnectSession();
  }

  createSession() {
    createSession({
      apiKey: this.props.apiKey,
      sessionId: this.props.sessionId,
      token: this.props.token,
    })
      .then(() => {
        OT.getSessionInfo((sessionInfo) => {
          this.setState({
            isConnected: true,
            sessionInfo,
          });
        });
        const signalData = sanitizeSignalData(this.props.signal);
        OT.sendSignal(signalData, signalData.errorHandler);
      })
      .catch((error) => {
        handleError(error);
      });
  }

  disconnectSession() {
    disconnectSession()
      .then(() => {
        this.setState({
          isConnected: false,
          sessionInfo: null,
        });
      })
      .catch((error) => {
        handleError(error);
      });
  }
  getSessionInfo() {
    return this.state.sessionInfo;
  }

  onStreamCreated = event => {
    const index = this.state.streams.findIndex(stream => stream.id === event.streamId);
    if (index < 0) {
      this.setState({
        streams: [...this.state.streams, event.streamId]
      })
    }
  }

  onStreamDestroyed = event => {
    const index = this.state.streams.findIndex(stream => stream.id === event.streamId);
    if (index >= 0) {
      this.setState({
        streams: this.state.streams.splice(index, 1)
      })
    }
  }

  render() {
    const { streams } = this.state;
    const { style } = this.props;

    if (this.state.isConnected && this.props.children) {
      const childrenWithProps = Children.map(
        this.props.children,
        child => {
          return (child ? cloneElement(
            child,
            {
              streams,
              sessionId: this.props.sessionId,
            },
          ) : child)
        },
      );
      return <View style={style}>{ childrenWithProps }</View>;
    }
    return <View />;
  }
}

OTSession.propTypes = {
  apiKey: PropTypes.string.isRequired,
  sessionId: PropTypes.string.isRequired,
  token: PropTypes.string.isRequired,
  children: PropTypes.oneOfType([
    PropTypes.element,
    PropTypes.arrayOf(PropTypes.element),
  ]),
  style: ViewPropTypes.style,
  eventHandlers: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  signal: PropTypes.object, // eslint-disable-line react/forbid-prop-types
};

OTSession.defaultProps = {
  eventHandlers: {},
  signal: {},
  style: {
    flex: 1
  },
};
