import React from 'react';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import { OT } from './OT';
import OTSubscriberViewNative from './OTSubscriberViewNativeComponent';
import OTContext from './contexts/OTContext';

export default class OTSubscriberView extends React.Component {
  static defaultProps = {
    subscribeToAudio: true,
    subscribeToVideo: true,
    style: {
      flex: 1,
    },
  };

  sessionId = this.context.sessionId;

  eventHandlers = {};

  constructor(props, context) {
    super(props, context);
    this.eventHandlers = props.eventHandlers;
    this.initComponent(props.eventHandlers);
  }

  initComponent = () => {
    this.eventHandlers.subscriberConnected =
      this.props.eventHandlers?.subscriberConnected;
    this.eventHandlers.onRtcStatsReport =
      this.props.eventHandlers?.onRtcStatsReport;
  };

  getRtcStatsReport() {
    //NOSONAR - this method is exposed externally
    OT.getSubscriberRtcStatsReport();
  }

  render() {
    const { style, streamId, subscribeToAudio, subscribeToVideo } = this.props;
    return (
      <OTSubscriberViewNative
        sessionId={this.sessionId}
        streamId={streamId}
        subscribeToAudio={subscribeToAudio}
        subscribeToVideo={subscribeToVideo}
        onSubscriberConnected={(event) => {
          this.eventHandlers?.subscriberConnected?.(event.nativeEvent);
        }}
        onRtcStatsReport={(event) => {
          this.eventHandlers?.rtcStatsReport?.(event.nativeEvent);
        }}
        onVideoEnabled={(event) => {
          this.eventHandlers?.videoEnabled?.(event.nativeEvent);
        }}
        style={style}
      />
    );
  }
}

OTSubscriberView.propTypes = {
  streamId: PropTypes.string.isRequired,
  eventHandlers: PropTypes.object,
  subscribeToAudio: PropTypes.bool,
  subscribeToVideo: PropTypes.bool,
  style: ViewPropTypes.style,
};

OTSubscriberView.defaultProps = {
  eventHandlers: {},
  subscribeToAudio: true,
  subscribeToVideo: true,
  style: {
    flex: 1,
  },
};

OTSubscriberView.contextType = OTContext;
