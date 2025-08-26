import React, { Component } from 'react';
import { View } from 'react-native';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import { OT } from './OT';
import {
  dispatchEvent,
  setIsConnected,
  addStream,
  removeStream,
  clearStreams,
} from './helpers/OTSessionHelper';
import { handleError } from './OTError';
import { logOT } from './helpers/OTHelper';
import OTContext from './contexts/OTContext';
import { sanitizeSessionOptions } from './helpers/OTSessionHelper';

export default class OTSession extends Component {
  eventHandlers = {};

  async initSession(apiKey, sessionId, token) {
    if (apiKey && sessionId && token) {
      logOT({
        apiKey,
        sessionId,
        action: 'rn_initialize',
        proxyUrl: this.props.options?.proxyUrl,
      });
    } else {
      handleError('Please check your OpenTok credentials.');
    }
    OT.onSessionConnected((event) => {
      this.connectionId = event.connectionId;
      setIsConnected(true);
      this.eventHandlers?.sessionConnected?.(event);
      dispatchEvent('sessionConnected', event);
      if (Object.keys(this.props.signal).length > 0) {
        this.signal(this.props.signal);
      }
    });
    OT.initSession(
      apiKey,
      sessionId,
      sanitizeSessionOptions(this.props.options)
    );
    OT.onStreamCreated((event) => {
      this.eventHandlers?.streamCreated?.(event);
      if (event.connectionId !== this.connectionId) {
        addStream(event.streamId);
      }
      dispatchEvent('streamCreated', event);
    });

    OT.onStreamDestroyed((event) => {
      this.eventHandlers?.streamDestroyed?.(event);
      removeStream(event.streamId);
      dispatchEvent('streamDestroyed', event);
    });

    OT.onSignalReceived((event) => {
      this.eventHandlers?.signal?.(event);
    });

    OT.onSessionError((event) => {
      this.eventHandlers?.error?.(event);
    });

    OT.onConnectionCreated((event) => {
      this.eventHandlers?.connectionCreated?.(event);
    });
    OT.onConnectionDestroyed((event) => {
      this.eventHandlers?.connectionDestroyed?.(event);
    });
    OT.onArchiveStarted((event) => {
      this.eventHandlers?.archiveStarted?.(event);
    });
    OT.onArchiveStopped((event) => {
      this.eventHandlers?.archiveStopped?.(event);
    });
    OT.onMuteForced((event) => {
      this.eventHandlers?.muteForced?.(event);
    });
    OT.onSessionReconnecting((event) => {
      this.eventHandlers?.sessionReconnecting?.(event);
    });
    OT.onSessionReconnected((event) => {
      this.eventHandlers?.sessionReconnected?.(event);
    });
    OT.onStreamPropertyChanged((event) => {
      this.eventHandlers?.streamPropertyChanged?.(event);
    });

    OT.connect(sessionId, token);
  }

  constructor(props) {
    super(props);
    this.eventHandlers = props.eventHandlers;
    this.initComponent(props.eventHandlers);
  }

  initComponent = () => {
    this.initSession(this.props.apiKey, this.props.sessionId, this.props.token);
  };

  signal(signalObj) {
    OT.sendSignal(
      this.props.sessionId,
      signalObj.type || '',
      signalObj.data || '',
      signalObj.to || ''
    );
  }

  disconnectSession(sessionId) {
    OT.disconnect(sessionId);
  }

  componentWillUnmount() {
    this.disconnectSession(this.props.sessionId);
    clearStreams();
  }

  render() {
    const { style, children, sessionId, apiKey, token } = this.props;

    if (children && sessionId && apiKey && token) {
      return (
        <OTContext.Provider
          value={{ sessionId, connectionId: this.connectionId }}
        >
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
  children: PropTypes.oneOfType([
    PropTypes.element,
    PropTypes.arrayOf(PropTypes.element),
  ]),
  style: ViewPropTypes.style,
  eventHandlers: PropTypes.object,
  options: PropTypes.object,
  signal: PropTypes.object,
  encryptionSecret: PropTypes.string,
};

OTSession.defaultProps = {
  eventHandlers: {},
  options: {},
  signal: {},
  style: {
    flex: 1,
  },
};
