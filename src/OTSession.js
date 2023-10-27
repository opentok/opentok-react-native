import React, { Component, Children, cloneElement } from 'react';
import { View } from 'react-native';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import { pick, isNull } from 'underscore';
import { nativeEvents, setNativeEvents, removeNativeEvents,  OT } from './OT';
import { sanitizeSessionEvents, sanitizeSessionOptions, sanitizeSignalData,
   sanitizeCredentials, getConnectionStatus } from './helpers/OTSessionHelper';
import { handleError } from './OTError';
import { logOT, getOtrnErrorEventHandler } from './helpers/OTHelper';
import OTContext from './contexts/OTContext';

export default class OTSession extends Component {
  constructor(props) {
    super(props);
    this.state = {
      sessionInfo: null,
    };
    this.componentEvents = {
      sessionDisconnected: Platform.OS === "android" ? "session:onDisconnected" : "session:sessionDidDisconnect",
    };
    this.componentEventsArray = Object.values(this.componentEvents);
    this.otrnEventHandler = getOtrnErrorEventHandler(this.props.eventHandlers);
    this.initComponent();
  }
  initComponent = () => {
    const credentials = pick(this.props, ["apiKey", "sessionId", "token"]);
    this.sanitizedCredentials = sanitizeCredentials(credentials);
    if (Object.keys(this.sanitizedCredentials).length === 3) {
      const sessionEvents = sanitizeSessionEvents(this.sanitizedCredentials.sessionId, this.props.eventHandlers);
      setNativeEvents(sessionEvents);
      OT.setJSComponentEvents(this.componentEventsArray);
      this.sessionDisconnected = nativeEvents.addListener(`${this.props.sessionId}:${this.componentEvents.sessionDisconnected}`, (session) =>
        this.sessionDisconnectedHandler(session)
      );
      
    }
  };
  componentDidMount() {
    const sessionOptions = sanitizeSessionOptions(this.props.options);
    const { apiKey, sessionId, token } = this.sanitizedCredentials;
    if (apiKey && sessionId && token) {
      this.createSession(this.sanitizedCredentials, sessionOptions);
      logOT({ apiKey, sessionId, action: 'rn_initialize', proxyUrl: sessionOptions.proxyUrl });
    } else {
      handleError('Please check your OpenTok credentials.');
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
        this.signal(value);
      }
    };

    updateSessionProperty("signal", {});
  }
  componentWillUnmount() {
    this.disconnectSession();
  }
  createSession(credentials, sessionOptions) {
    const { signal } = this.props;
    const { apiKey, sessionId, token } = credentials;
    OT.initSession(apiKey, sessionId, sessionOptions);
    OT.connect(sessionId, token, (error) => {
      if (error) {
        this.otrnEventHandler(error);
      } else {
        OT.getSessionInfo(sessionId, (session) => {
          if (!isNull(session)) {
            const sessionInfo = { ...session, connectionStatus: getConnectionStatus(session.connectionStatus) };
            this.setState({
              sessionInfo,
            });
            logOT({ apiKey, sessionId, action: "rn_on_connect", proxyUrl: sessionOptions.proxyUrl, connectionId: session.connection.connectionId });
            if (Object.keys(signal).length > 0) {
              this.signal(signal);
            }
          }
        });
      }
    });
  }
  disconnectSession() {
    OT.disconnectSession(this.props.sessionId, (disconnectError) => {
      if (disconnectError) {
        this.otrnEventHandler(disconnectError);
      }
      const events = sanitizeSessionEvents(this.props.sessionId, this.props.eventHandlers);
      removeNativeEvents(events);
    });
  }
  getSessionInfo() {
    return this.state.sessionInfo;
  }
  signal(signal) {
    const signalData = sanitizeSignalData(signal);
    OT.sendSignal(this.props.sessionId, signalData.signal, signalData.errorHandler);
  }

  sessionDisconnectedHandler = (session) => {
    const events = sanitizeSessionEvents(this.props.sessionId, this.props.eventHandlers);
    removeNativeEvents(events);
  };

  render() {
    const { style, children, sessionId, apiKey, token } = this.props;
    const { sessionInfo } = this.state;
    if (children && sessionId && apiKey && token) {
      return (
        <OTContext.Provider value={{ sessionId, sessionInfo }}>
          <View style={style}>{children}</View>
        </OTContext.Provider>
      );
    }
    return <View />;
  }
}

OTSession.propTypes = {
  apiKey: PropTypes.string.isRequired,
  sessionId: PropTypes.string.isRequired,
  token: PropTypes.string.isRequired,
  children: PropTypes.oneOfType([PropTypes.element, PropTypes.arrayOf(PropTypes.element)]),
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
