import React, { Component, Children, cloneElement } from 'react';
import { View, ViewPropTypes } from 'react-native';
import PropTypes from 'prop-types';
import { isNull } from 'underscore';
import { setNativeEvents, removeNativeEvents, OT } from './OT';
import {
  sanitizeSessionEvents, sanitizeSessionOptions, sanitizeSignalData,
  sanitizeCredentials, getConnectionStatus,
} from './helpers/OTSessionHelper';
import { logOT, getOtrnErrorEventHandler } from './helpers/OTHelper';

export default class OTSession extends Component {
  constructor(props) {
    super(props);
    this.state = {
      sessionInfo: null,
    };
    const { eventHandlers } = this.props;
    this.eventHandlers = eventHandlers;
    this.otrnEventHandler = getOtrnErrorEventHandler(eventHandlers);
  }

  componentWillMount() {
    const {
      options, apiKey, sessionId, token,
    } = this.props;
    const credentials = {
      apiKey,
      sessionId,
      token,
    };
    const sanitizedCredentials = sanitizeCredentials(credentials);
    if (Object.keys(sanitizedCredentials).length === 3) {
      const sessionEvents = sanitizeSessionEvents(this.eventHandlers);
      const sessionOptions = sanitizeSessionOptions(options);
      setNativeEvents(sessionEvents);
      this.createSession(sanitizedCredentials, sessionOptions);
      logOT(sanitizedCredentials.apiKey, sanitizedCredentials.sessionId, 'rn_initialize');
    }
  }

  componentDidUpdate(previousProps) {
    const { props } = this;
    const useDefault = (value, defaultValue) => (value === undefined ? defaultValue : value);
    const shouldUpdate = (key, defaultValue) => {
      const previous = useDefault(previousProps[key], defaultValue);
      const current = useDefault(props[key], defaultValue);
      return previous !== current;
    };

    const updateSessionProperty = (key, defaultValue) => {
      if (shouldUpdate(key, defaultValue)) {
        const value = useDefault(props[key], defaultValue);
        this.signal(value);
      }
    };

    updateSessionProperty('signal', {});
  }

  componentWillUnmount() {
    this.disconnectSession();
  }

  getSessionInfo() {
    const { sessionInfo } = this.state;
    return sessionInfo;
  }

  disconnectSession() {
    OT.disconnectSession((disconnectError) => {
      if (disconnectError) {
        this.otrnEventHandler(disconnectError);
      } else {
        const events = sanitizeSessionEvents(this.eventHandlers);
        removeNativeEvents(events);
      }
    });
  }

  createSession(credentials, sessionOptions) {
    const { apiKey, sessionId, token } = credentials;
    const { signal } = this.props;
    OT.initSession(apiKey, sessionId, sessionOptions);
    OT.connect(token, (error) => {
      if (error) {
        this.otrnEventHandler(error);
      } else {
        OT.getSessionInfo((session) => {
          if (!isNull(session)) {
            const { connectionStatus, connection } = session;
            const sessionInfo = {
              ...session,
              connectionStatus: getConnectionStatus(connectionStatus),
            };
            this.setState({
              sessionInfo,
            });
            logOT(apiKey, sessionId, 'rn_on_connect', connection.connectionId);
            this.signal(signal);
          }
        });
      }
    });
  }

  signal(signalInput) {
    const signalData = sanitizeSignalData(signalInput);
    OT.sendSignal(signalData.signal, signalData.errorHandler);
  }

  render() {
    const { style, children, sessionId } = this.props;
    if (children) {
      const childrenWithProps = Children.map(
        children,
        child => (child ? cloneElement(
          child,
          {
            sessionId,
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
  options: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  signal: PropTypes.object, // eslint-disable-line react/forbid-prop-types
};

OTSession.defaultProps = {
  eventHandlers: {},
  options: {},
  signal: {},
  style: {
    flex: 1,
  },
};
