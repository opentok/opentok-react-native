import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { View, Platform } from 'react-native';
import { isNull } from 'underscore';
import {
  checkAndroidPermissions, OT, removeNativeEvents, nativeEvents, setNativeEvents,
} from './OT';
import { sanitizeProperties, sanitizePublisherEvents } from './helpers/OTPublisherHelper';
import OTPublisherView from './views/OTPublisherView';
import { getOtrnErrorEventHandler } from './helpers/OTHelper';
import { isConnected } from './helpers/OTSessionHelper';

const uuid = require('uuid/v4');

class OTPublisher extends Component {
  constructor(props) {
    super(props);
    this.state = {
      initError: null,
      publisher: null,
    };
    this.publisherId = uuid();
    this.componentEvents = {
      sessionConnected: Platform.OS === 'android' ? 'session:onConnected' : 'session:sessionDidConnect',
    };
    this.componentEventsArray = Object.values(this.componentEvents);
    const { eventHandlers } = this.props;
    this.eventHandlers = eventHandlers;
    this.otrnEventHandler = getOtrnErrorEventHandler(this.eventHandlers);
  }

  componentWillMount() {
    const publisherEvents = sanitizePublisherEvents(this.publisherId, this.eventHandlers);
    setNativeEvents(publisherEvents);
    OT.setJSComponentEvents(this.componentEventsArray);
    this.sessionConnected = nativeEvents.addListener(
      this.componentEvents.sessionConnected,
      () => this.sessionConnectedHandler(),
    );
  }

  componentDidMount() {
    this.createPublisher();
  }

  componentDidUpdate(previousProps) {
    const { properties } = this.props;
    const useDefault = (value, defaultValue) => (value === undefined ? defaultValue : value);
    const shouldUpdate = (key, defaultValue) => {
      const previous = useDefault(previousProps.properties[key], defaultValue);
      const current = useDefault(properties[key], defaultValue);
      return previous !== current;
    };

    const updatePublisherProperty = (key, defaultValue) => {
      if (shouldUpdate(key, defaultValue)) {
        const value = useDefault(properties[key], defaultValue);
        if (key === 'cameraPosition') {
          OT.changeCameraPosition(this.publisherId, value);
        } else {
          OT[key](this.publisherId, value);
        }
      }
    };

    updatePublisherProperty('publishAudio', true);
    updatePublisherProperty('publishVideo', true);
    updatePublisherProperty('cameraPosition', 'front');
  }

  componentWillUnmount() {
    OT.destroyPublisher(this.publisherId, (error) => {
      if (error) {
        this.otrnEventHandler(error);
      } else {
        this.sessionConnected.remove();
        OT.removeJSComponentEvents(this.componentEventsArray);
        const events = sanitizePublisherEvents(this.publisherId, this.eventHandlers);
        removeNativeEvents(events);
      }
    });
  }

  sessionConnectedHandler = () => {
    const { initError } = this.state;
    if (isNull(this.publisher) && isNull(initError)) {
      this.publish();
    }
  }

  createPublisher() {
    if (Platform.OS === 'android') {
      checkAndroidPermissions()
        .then(() => {
          this.initPublisher();
        })
        .catch((error) => {
          this.otrnEventHandler(error);
        });
    } else {
      this.initPublisher();
    }
  }

  initPublisher() {
    const { properties } = this.props;
    const publisherProperties = sanitizeProperties(properties);
    OT.initPublisher(this.publisherId, publisherProperties, (initError) => {
      if (initError) {
        this.setState({
          initError,
        });
        this.otrnEventHandler(initError);
      } else {
        OT.getSessionInfo((session) => {
          if (!isNull(session) && isNull(this.publisher) && isConnected(session.connectionStatus)) {
            this.publish();
          }
        });
      }
    });
  }

  publish() {
    OT.publish(this.publisherId, (publishError) => {
      if (publishError) {
        this.otrnEventHandler(publishError);
      } else {
        this.setState({
          publisher: true,
        });
      }
    });
  }

  render() {
    const { publisher } = this.state;
    if (publisher && this.publisherId) {
      return <OTPublisherView publisherId={this.publisherId} {...this.props} />;
    }
    return <View />;
  }
}

const viewPropTypes = View.propTypes;
OTPublisher.propTypes = {
  ...viewPropTypes,
  properties: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  eventHandlers: PropTypes.object, // eslint-disable-line react/forbid-prop-types
};
OTPublisher.defaultProps = {
  properties: {},
  eventHandlers: {},
};
export default OTPublisher;
