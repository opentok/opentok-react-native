### OTSubscriber Component

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| sessionId | String | No | OpenTok Session Id. This is auto populated by wrapping `OTSubscriber` with `OTSession`
| streamId | String| No | OpenTok Subscriber streamId. This is auto populated inside the `OTSubscriber` component when `streamCreated` event is fired from the native instance
| properties | Object | No | Properties passed into the native subscriber instance
| streamProperties | Object | No | Used to update individual subscriber instance properties
| eventHandlers | Object&lt;Function&gt; | No | Event handlers passed into the native subscriber instance
| subscribeToSelf | Boolean | No | If set to true, the subscriber can subscribe to it's own publisher stream (default: false)
| children | Function | No | A render prop allowing individual rendering of each stream

## Properties
  * **subscribeToAudio** (Boolean) — Whether to subscribe to audio.

  * **subscribeToVideo** (Boolean) — Whether to subscribe video.

  * **preferredResolution** (String) — Sets the preferred resolution of the subscriber's video. The format of the string is "widthxheight", where the width and height are represented in pixels. Valid values are "1280x720", "640x480", and "352x288".

  * **preferredFrameRate** (Number) — Set this to the desired frame rate (in frames per second). Set this to null to remove the preferred frame rate, and the client will use the highest frame rate available. Valid values are 30, 15, 7, and 1.

  * **audioVolume** (Number) — Sets the audio volume, between 0 and 100, of the subscriber. If the value is not in this range, it will be clamped to it.

The `OTSubscriber` component will subscribe to a specified stream from a specified session upon mounting. The `OTSubscriber` component will stop subscribing and unsubscribing when it's unmounting.

## Methods

**getRtcStatsReport(streamId)** Gets the RTC stats report for the subscriber to the stream with the
specified stream ID. This is an asynchronous operation. The OTSubscriber object dispatches an
`rtcStatsReport` event when RTC statistics for the subscriber are available.

## Events

  * **audioLevel** (SubscriberAudioLevelEvent) — Sent on a regular interval with the recent representative audio level.
  See [SubscriberAudioLevelEvent](./EventData.md#SubscriberAudioLevelEvent)

  * **audioNetworkStats** (Object) — Sent periodically to report audio statistics for the subscriber.
  A [AudioNetworkStats](./EventData.md#AudioNetworkStats) object is passed into the event handler.

  * **connected** () — Sent when the subscriber successfully connects to the stream. The event object
    includes a `streamId` property, identifying the stream.

  * **disconnected** () — Called when the subscriber’s stream has been interrupted.

  * **error** (Object) — Sent if the subscriber fails to connect to its stream.

  * **otrnError** (Object) — Sent if there is an error with the communication between the native subscriber instance and the JS component.

* **rtcStatsReport** (Object) -- Sent when RTC stats reports are available for the subscriber,
  in response to calling the `OTSubscriber.getRtcStatsReport()` method. A
  [SubscriberRtcStatsReportEvent](./EventData.md#subscriberRtcStatsReportEvent) object is passed
  into the event handler. This event object has the following properties:

  * `jsonArrayOfReports` property, which is a JSON array of RTCStatsReport for the media stream.
    The structure of the JSON array is similar to the format of the RtcStatsReport object implemented
    in web browsers (see the
    [Mozilla docs](https://developer.mozilla.org/en-US/docs/Web/API/RTCStatsReport)).
    Also see [this W3C documentation](https://w3c.github.io/webrtc-stats/).
  
  * `stream` -- An object representing the subscriber's stream. This object includes a `streamId`
    property, identifying the stream.

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
      audioNetworkStats: event => {
        console.log('audioNetworkStats', event);
        // { timeStamp: 1643203644833, audioPacketsLost: 0, audioPacketsReceived: 64, audioBytesReceived: 5574 }
      },
      videoNetworkStats: event => {
        console.log('videoNetworkStats', event);
        // videoBytesReceived: 706635, videoPacketsLost: 0, timeStamp: 1643203644724, videoPacketsReceived: 656 }
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

## Custom rendering of streams

`OTSubscriber` accepts a render prop function that enables custom rendering of individual streams, e.g. to allow touch interaction or provide individual styling for each `OTSubscriberView`.
An array of stream IDs is passed to the render prop function as its only argument.

For example, to display the stream, pass its ID as `streamId` prop to the `OTSubscriberView` component:

```js
import { OTSubscriberView } from 'opentok-react-native'

// Render method

<OTSubscriber>
  {this.renderSubscribers}
</OTSubscriber>

// Render prop function

renderSubscribers = (subscribers) => {
  return subscribers.map((streamId) => (
    <TouchableOpacity
      onPress={() => this.handleStreamPress(streamId)}
      key={streamId}
      style={subscriberWrapperStyle}
    >
      <OTSubscriberView streamId={streamId} style={subscriberStyle} />
    </TouchableOpacity>
  ));
};
```

Note: `streamProperties` prop is ignored if a children prop is passed.



