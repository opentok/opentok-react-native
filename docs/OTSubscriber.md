### OTSubscriber Component

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| sessionId | String | No | OpenTok Session Id. This is auto populated by wrapping `OTSubscriber` with `OTSession`
| streamId | String| No | OpenTok Subscriber streamId. This is auto populated inside the `OTSubscriber` component when `streamCreated` event is fired from the native instance
| properties | Object | No | Properties passed into the native subscriber instance
| streamProperties | Object | No | Used to update individual subscriber instance properties
| eventHandlers | Object&lt;Function&gt; | No | Event handlers passed into the native subscriber instance

## Properties 
  * **subscribeToAudio** (Boolean) — Whether to subscribe to audio.

  * **subscribeToVideo** (Boolean) — Whether to subscribe video.


The `OTSubscriber` component will subscribe to a specified stream from a specified session upon mounting. The `OTSubscriber` component will stop subscribing and unsubscribing when it's unmounting.

## Events
  * **audioLevel** (String) — Sent on a regular interval with the recent representative audio level.

  * **audioNetworkStats** (Object) — Sent periodically to report audio statistics for the subscriber.

  * **connected** () — Sent when the subscriber successfully connects to the stream.

  * **disconnected** () — Called when the subscriber’s stream has been interrupted.
  
  * **error** (Object) — Sent if the subscriber fails to connect to its stream.

  * **videoDataReceived** () - Sent when a frame of video has been decoded. Although the subscriber will connect in a relatively short time, video can take more time to synchronize. This message is sent after the `connected` message is sent.
  
  * **videoDisabled** (String) — This message is sent when the subscriber stops receiving video. Check the reason parameter for the reason why the video stopped.

  * **videoDisableWarning** () - This message is sent when the OpenTok Media Router determines that the stream quality has degraded and the video will be disabled if the quality degrades further. If the quality degrades further, the subscriber disables the video and the `videoDisabled` message is sent. If the stream quality improves, the `videoDisableWarningLifted` message is sent.

  * **videoDisableWarningLifted** () — This message is sent when the subscriber’s video stream starts (when there previously was no video) or resumes (after video was disabled). Check the reason parameter for the reason why the video started (or resumed).

  * **videoEnabled** (String) - This message is sent when the subscriber’s video stream starts (when there previously was no video) or resumes (after video was disabled). Check the reason parameter for the reason why the video started (or resumed).
  
  * **videoNetworkStats** (Object) — Sent periodically to report video statistics for the subscriber.

  ```js
class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      streamProperties: {},
    };

    this.subscriberProperties = {
      subscribeToAudio: false,
      subscribeToVideo: true,
    };

    this.sessionEventHandlers = {
      streamCreated: event => {
        const streamProperties = {...this.state.streamProperties, [event.streamId]: {
          subscribeToAudio: true,
          subscribeToVideo: false,
          style: {
            width: 400,
            height: 300,
          },
        }};
        this.setState({ streamProperties });
      },
    };

    this.subscriberEventHandlers = {
      error: (error) => {
        console.log(`There was an error with the subscriber: ${error}`);
      },
    };
  }

  render() {
    return (
      <OTSession apiKey="your-api-key" sessionId="your-session-id" token="your-session-token" eventHandlers={this.sessionEventHandlers}>
        <OTSubscriber
          properties={this.subscriberProperties}
          eventHandlers={this.subscriberEventHandlers}
          style={{ height: 100, width: 100 }}
          streamProperties={this.state.streamProperties}
        />
      </OTSession>
    );
  }
}
```