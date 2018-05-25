import React, { Component, Children, cloneElement } from 'react';
import { View, ViewPropTypes } from 'react-native';
import PropTypes from 'prop-types';
import { setNativeEvents, removeNativeEvents,  OT } from './OT';
import { sanitizeSessionEvents, sanitizeSignalData, sanitizeCredentials, getConnectionStatus } from './helpers/OTSessionHelper';
import { logOT } from './helpers/OTHelper';
import { handleError } from './OTError';
import { pick, isNull } from 'underscore';

export default class OTSession extends Component {
  constructor(props) {
    super(props);
    this.state = {
      sessionInfo: null,
    };
  }
  componentWillMount() {
    const credentials = pick(this.props, ['apiKey', 'sessionId', 'token']);
    const sanitizedCredentials = sanitizeCredentials(credentials);
    if (Object.keys(sanitizedCredentials).length === 3) {
      const sessionEvents = sanitizeSessionEvents(this.props.eventHandlers);
      setNativeEvents(sessionEvents);
      this.createSession(sanitizedCredentials);
      logOT(sanitizedCredentials.apiKey, sanitizedCredentials.sessionId, 'rn_initialize');
    }
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
    this.disconnectSession();
  }
  createSession(credentials) {
    OT.initSession(credentials.apiKey, credentials.sessionId);    
    OT.connect(credentials.token, (error) => {
      if (error) {
        handleError(error);
      } else {
        OT.getSessionInfo((session) => {
          if (!isNull(session)) {
            const sessionInfo = { ...session, connectionStatus: getConnectionStatus(session.connectionStatus)};
            this.setState({
              sessionInfo,
            });
            logOT(credentials.apiKey, credentials.sessionId, 'rn_on_connect', session.connection.connectionId);
            const signalData = sanitizeSignalData(this.props.signal);
            OT.sendSignal(signalData, signalData.errorHandler);
          }
        });
      }
    });
  }
  disconnectSession() {
    OT.disconnectSession((disconnectError) => {
      if (disconnectError) {
        handleError(disconnectError);
      } else { 
        const events = sanitizeSessionEvents(this.props.eventHandlers);
        removeNativeEvents(events);
      }
    });
  }
  getSessionInfo() {
    return this.state.sessionInfo;
  }
  render() {

    const { style } = this.props;
    
    if (this.props.children) {
      const childrenWithProps = Children.map(
        this.props.children,
        child => (child ? cloneElement(
          child,
          {
            sessionId: this.props.sessionId,
          },
        ) : child),
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
