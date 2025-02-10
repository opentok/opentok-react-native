import React, { Component } from 'react';
import { View } from 'react-native';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import { OT } from './OT';

export default class OTSession extends Component {
  eventHandlers = {};
  async initSession(apiKey, sessionId, token) {
    OT.onSessionConnected((event: SessionConnectEvent) => {
      this.eventHandlers.sessionConnected(event);
      if (Object.keys(this.props.signal).length > 0) {
        this.signal(this.props.signal);
      }
    });
    OT.initSession(apiKey, sessionId, {});
    OT.onStreamCreated((event) => {
      this.eventHandlers.streamCreated(event);
    });
    /* TO DO:
    OT.onStreamDestroyed((event) => {
      this.eventHandlers.onStreamDestroyed(event);
    });
    */
    OT.onSignalReceived((event) => {
      this.eventHandlers.signal(event);
    });

    OT.onSessionError((event) => {
      this.eventHandlers.error(event);
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
    this.eventHandlers.sessionConnected = this.props.eventHandlers?.sessionConnected;
  };

  signal(signalObj) {
    OT.sendSignal(this.props.sessionId, signalObj.type, signalObj.data);
  }

  render() {
    const { style, children, sessionId, apiKey, token } = this.props;
    if (children && sessionId && apiKey && token) {
      return (
        <View style={style}>
          { children }
        </View>
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
    flex: 1,
  },
};
