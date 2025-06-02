import React from 'react';
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
    const { streamId } = this.props;
    const subscriberProperties = this.context.subscriberProperties;
    const streamProperties = this.context.streamProperties
      ? this.context.streamProperties[streamId]
      : undefined;
    let {
      audioVolume,
      preferredFrameRate,
      preferredResolution,
      subscribeToAudio,
      subscribeToCaptions,
      subscribeToVideo,
      style,
    } = subscriberProperties;
    if (streamProperties) {
      ({
        audioVolume,
        preferredFrameRate,
        preferredResolution,
        subscribeToAudio,
        subscribeToCaptions,
        subscribeToVideo,
        style,
      } = streamProperties);
    }
    return (
      <OTSubscriberViewNative
        sessionId={this.sessionId}
        streamId={streamId}
        subscribeToAudio={subscribeToAudio}
        subscribeToVideo={subscribeToVideo}
        subscribeToCaptions={subscribeToCaptions}
        preferredFrameRate={preferredFrameRate}
        preferredResolution={preferredResolution}
        audioVolume={audioVolume}
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
};

OTSubscriberView.defaultProps = {
  eventHandlers: {},
};

OTSubscriberView.contextType = OTContext;
