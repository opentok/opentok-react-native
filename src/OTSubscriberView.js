import React from 'react';
import { ViewPropTypes } from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';
import { OT } from './OT';
import OTSubscriberViewNative from './OTSubscriberViewNativeComponent';

export default class OTSubscriberView extends React.Component {
  static defaultProps = {
    subscribeToAudio: true,
    subscribeToVideo: true,
    style: {
      flex: 1,
    },
  };

  eventHandlers = {};

  constructor(props) {
    super(props);
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
    const { style, sessionId, streamId, subscribeToAudio, subscribeToVideo } =
      this.props;
    return (
      <OTSubscriberViewNative
        sessionId={sessionId}
        streamId={streamId}
        subscribeToAudio={subscribeToAudio}
        subscribeToVideo={subscribeToVideo}
        onSubscriberConnected={(event) => {
          this.eventHandlers.subscriberConnected(event.nativeEvent);
        }}
        onRtcStatsReport={(event) => {
          this.eventHandlers.onRtcStatsReport(event.nativeEvent);
        }}
        style={style}
      />
    );
  }
}

OTSubscriberView.propTypes = {
  sessionId: PropTypes.string.isRequired,
  streamId: PropTypes.string.isRequired,
  eventHandlers: PropTypes.object, // eslint-disable-line react/forbid-prop-types
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
