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
  }

  getRtcStatsReport() {
    //NOSONAR - this method is exposed externally
    OT.getSubscriberRtcStatsReport();
  }

  render() {
    const { streamId } = this.props;
    const subscriberProperties = this.context.subscriberProperties;
    const eventHandlers = this.context.eventHandlers;
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
        onAudioLevel={(event) => {
          eventHandlers.audioLevel?.(event.nativeEvent);
        }}
        onAudioNetworkStats={(event) => {
          eventHandlers.audioNetworkStats?.(event.nativeEvent);
        }}
        onSubscriberConnected={(event) => {
          eventHandlers.subscriberConnected?.(event.nativeEvent);
        }}
        onRtcStatsReport={(event) => {
          eventHandlers.rtcStatsReport?.(event.nativeEvent);
        }}
        onVideoEnabled={(event) => {
          eventHandlers.videoEnabled?.(event.nativeEvent);
        }}
        onVideoNetworkStats={(event) => {
          eventHandlers.onVideoNetworkStats?.(event.nativeEvent);
        }}
        style={style}
      />
    );
  }
}

OTSubscriberView.propTypes = {
  streamId: PropTypes.string.isRequired,
};

OTSubscriberView.contextType = OTContext;
