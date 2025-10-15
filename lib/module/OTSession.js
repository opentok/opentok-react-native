"use strict";

import React, { Component } from 'react';
import { View } from 'react-native';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import { OT } from "./OT.js";
import { dispatchEvent, setIsConnected, addStream, removeStream, clearStreams } from "./helpers/OTSessionHelper.js";
import { handleError } from "./OTError.js";
import { logOT } from "./helpers/OTHelper.js";
import OTContext from "./contexts/OTContext.js";
import { sanitizeSessionOptions } from "./helpers/OTSessionHelper.js";
import { jsx as _jsx } from "react/jsx-runtime";
export default class OTSession extends Component {
  eventHandlers = {};
  async initSession(apiKey, sessionId, token) {
    if (apiKey && sessionId && token) {
      logOT({
        apiKey,
        sessionId,
        action: 'rn_initialize',
        proxyUrl: this.props.options?.proxyUrl
      });
    } else {
      handleError('Please check your OpenTok credentials.');
    }
    OT.onSessionConnected(event => {
      if (event.sessionId !== sessionId) return;
      this.connectionId = event.connectionId;
      setIsConnected(sessionId, true);
      this.eventHandlers?.sessionConnected?.(event);
      dispatchEvent(sessionId, 'sessionConnected', event);
      if (Object.keys(this.props.signal).length > 0) {
        this.signal(this.props.signal);
      }
    });
    OT.initSession(apiKey, sessionId, sanitizeSessionOptions(this.props.options));
    if (this.props.encryptionSecret) {
      this.setEncryptionSecret(this.props.encryptionSecret);
    }
    OT.onStreamCreated(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.streamCreated?.(event);
      if (event.connectionId !== this.connectionId) {
        addStream(sessionId, event.streamId);
      }
      dispatchEvent(sessionId, 'streamCreated', event);
    });
    OT.onStreamDestroyed(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.streamDestroyed?.(event);
      removeStream(sessionId, event.streamId);
      dispatchEvent(sessionId, 'streamDestroyed', event);
    });
    OT.onSignalReceived(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.signal?.(event);
    });
    OT.onSessionError(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.error?.(event);
    });
    OT.onConnectionCreated(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.connectionCreated?.(event);
    });
    OT.onConnectionDestroyed(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.connectionDestroyed?.(event);
    });
    OT.onArchiveStarted(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.archiveStarted?.(event);
    });
    OT.onArchiveStopped(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.archiveStopped?.(event);
    });
    OT.onMuteForced(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.muteForced?.(event);
    });
    OT.onSessionReconnecting(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.sessionReconnecting?.(event);
    });
    OT.onSessionReconnected(event => {
      if (event.sessionId !== sessionId) return;
      this.eventHandlers?.sessionReconnected?.(event);
    });
    OT.onStreamPropertyChanged(event => {
      if (event.sessionId !== sessionId) return;
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
  reportIssue() {
    return OT.reportIssue(this.props.sessionId);
  }
  getCapabilities() {
    return OT.getCapabilities(this.props.sessionId);
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
  signal(signalObj) {
    OT.sendSignal(this.props.sessionId, signalObj.type || '', signalObj.data || '', signalObj.to || '');
  }
  setEncryptionSecret(value) {
    OT.setEncryptionSecret(this.props.sessionId, value);
  }
  forceDisconnect(connectionId) {
    return OT.forceDisconnect(this.props.sessionId, connectionId);
  }
  disconnectSession(sessionId) {
    OT.disconnect(sessionId);
  }
  componentDidUpdate(previousProps) {
    const shouldUseDefault = (value, defaultValue) => value === undefined ? defaultValue : value;
    const shouldUpdate = (key, defaultValue) => {
      const previous = shouldUseDefault(previousProps[key], defaultValue);
      const current = shouldUseDefault(this.props[key], defaultValue);
      return previous !== current;
    };
    const updateSessionProperty = (key, defaultValue) => {
      if (shouldUpdate(key, defaultValue)) {
        const value = shouldUseDefault(this.props[key], defaultValue);
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
    this.disconnectSession(this.props.sessionId);
    clearStreams(this.props.sessionId);
  }
  render() {
    const {
      style,
      children,
      sessionId,
      apiKey,
      token
    } = this.props;
    if (children && sessionId && apiKey && token) {
      return /*#__PURE__*/_jsx(OTContext.Provider, {
        value: {
          sessionId,
          connectionId: this.connectionId
        },
        children: /*#__PURE__*/_jsx(View, {
          style: style,
          children: children
        })
      });
    }
    return /*#__PURE__*/_jsx(View, {});
  }
}
OTSession.propTypes = {
  apiKey: PropTypes.string.isRequired,
  sessionId: PropTypes.string.isRequired,
  token: PropTypes.string.isRequired,
  children: PropTypes.oneOfType([PropTypes.element, PropTypes.arrayOf(PropTypes.element)]),
  style: ViewPropTypes.style,
  eventHandlers: PropTypes.object,
  options: PropTypes.object,
  signal: PropTypes.object,
  encryptionSecret: PropTypes.string
};
OTSession.defaultProps = {
  eventHandlers: {},
  options: {},
  signal: {},
  style: {
    flex: 1
  }
};
//# sourceMappingURL=OTSession.js.map