import React, { Component, Children, cloneElement } from 'react';
import { View } from 'react-native';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import { pick, isNull } from 'underscore';
import { setNativeEvents, removeNativeEvents,  OT } from './OT';
import { sanitizeSessionEvents, sanitizeSessionOptions, sanitizeSignalData,
   sanitizeCredentials, sanitizeEncryptionSecret, getConnectionStatus } from './helpers/OTSessionHelper';
import { handleError } from './OTError';
import { logOT, getOtrnErrorEventHandler } from './helpers/OTHelper';
import OTContext from './contexts/OTContext';

export default class OTSession extends Component {
  constructor(props) {
    super(props);
    this.state = {
      sessionInfo: null,
    };
    this.otrnEventHandler = getOtrnErrorEventHandler(this.props.eventHandlers);
    this.initComponent();
  }
  initComponent = () => {
    const credentials = pick(this.props, ['apiKey', 'sessionId', 'token']);
    this.sanitizedCredentials = sanitizeCredentials(credentials);
    if (Object.keys(this.sanitizedCredentials).length === 3) {
      const sessionEvents = sanitizeSessionEvents(this.sanitizedCredentials.sessionId, this.props.eventHandlers);
      setNativeEvents(sessionEvents);
    }
  }
  componentDidMount() {
    const sessionOptions = sanitizeSessionOptions(this.props.options);
    const encryptionSecret = sanitizeEncryptionSecret(this.props.encryptionSecret);
    const { apiKey, sessionId, token } = this.sanitizedCredentials;
    if (apiKey && sessionId && token) {
      this.createSession(this.sanitizedCredentials, sessionOptions, encryptionSecret);
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
        if (key === 'signal') {
          this.signal(value);
        }
        if (key === 'encryptionSecret') {
          this.setEncryptionSecret(value);
        }
      }
    };

    updateSessionProperty('signal', {});
    updateSessionProperty('encryptionSecret', undefined);
  }
  componentWillUnmount() {
    this.disconnectSession();
  }
  createSession(credentials, sessionOptions, encryptionSecret) {
    const { signal } = this.props;
    const { apiKey, sessionId, token } = credentials;
    OT.initSession(apiKey, sessionId, sessionOptions);
    if (encryptionSecret) {
      this.setEncryptionSecret(encryptionSecret);
    }
    OT.connect(sessionId, token, (error) => {
      if (error) {
        this.otrnEventHandler(error);
      } else {
        OT.getSessionInfo(sessionId, (session) => {
          if (!isNull(session)) {
            const sessionInfo = { ...session, connectionStatus: getConnectionStatus(session.connectionStatus)};
            this.setState({
              sessionInfo,
            });
            logOT({ apiKey, sessionId, action: 'rn_on_connect', proxyUrl: sessionOptions.proxyUrl, connectionId: session.connection.connectionId });
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
      } else {
        const events = sanitizeSessionEvents(this.props.sessionId, this.props.eventHandlers);
        removeNativeEvents(events);
      }
    });
  }
  getSessionInfo() {
    return this.state.sessionInfo;
  }
  getCapabilities() {
    return new Promise((resolve, reject ) => {
      OT.getSessionCapabilities(this.props.sessionId, (sessionCapabilities) => {
        if (sessionCapabilities) {
          resolve(sessionCapabilities);
        } else {
          reject(new Error('Not connected to session.'));
        }
      });
    });
  }
  async reportIssue() {
    return new Promise((resolve, reject) => {
      OT.reportIssue(this.props.sessionId, (reportIssueId, error) => {
        if (reportIssueId) {
          resolve(reportIssueId)
        } else {
          reject (new Error(error))
        }
      });
    })
  }
  signal(signal) {
    const signalData = sanitizeSignalData(signal);
    OT.sendSignal(this.props.sessionId, signalData.signal, signalData.errorHandler);
  }
  forceMuteAll(excludedStreamIds) {
    return OT.forceMuteAll(this.props.sessionId, excludedStreamIds || []);
  }
  forceMuteStream(streamId) {
    return OT.forceMuteStream(this.props.sessionId, streamId);
  }
  disableForceMute() {
    return OT.disableForceMute(this.props.sessionId);
  }
  setEncryptionSecret(secret) {
    const errorHandler = this.props.eventHandlers.error;
    OT.setEncryptionSecret(this.props.sessionId, sanitizeEncryptionSecret(secret), (error) => {
      if (error && errorHandler) {
        errorHandler(error);
      }
    });
  }
  render() {
    const { style, children, sessionId, apiKey, token } = this.props;
    const { sessionInfo } = this.state;
    if (children && sessionId && apiKey && token) {
      return (
        <OTContext.Provider value={{ sessionId, sessionInfo }}>
          <View style={style}>
            { children }
          </View>
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
  children: PropTypes.oneOfType([
    PropTypes.element,
    PropTypes.arrayOf(PropTypes.element),
  ]),
  style: ViewPropTypes.style,
  eventHandlers: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  options: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  signal: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  encryptionSecret: PropTypes.string,
};

OTSession.defaultProps = {
  eventHandlers: {},
  options: {},
  signal: {},
  style: {
    flex: 1
  },
};
