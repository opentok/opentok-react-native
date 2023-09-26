# OTPublisher component

[Properties](#properties)
[properties object](#properties-object)
[Events](#events)

The `OTPublisher` component will initialize a publisher and publish to the specified session upon mounting. To destroy the publisher, unmount the `OTPublisher` component. Please keep in mind that the publisher view is not removed unless you specifically unmount the `OTPublisher` component.

Add the OTPublisher component as a child of the OTSession component:

```js
class App extends Component {
  constructor(props) {
    super(props);

    this.publisherProperties = {
      publishAudio: false,
      cameraPosition: 'front'
    };

    this.publisherEventHandlers = {
      streamCreated: event => {
        console.log('Publisher stream created!', event);
      },
      streamDestroyed: event => {
        console.log('Publisher stream destroyed!', event);
      }
    };
  }

  render() {
    return (
      <OTSession apiKey="your-api-key" sessionId="your-session-id" token="your-session-token">
        <OTPublisher
          properties={this.publisherProperties}
          eventHandlers={this.publisherEventHandlers}
          style={{ height: 100, width: 100 }}
        />
      </OTSession>
    );
  }
}
```

## Properties

The OTPublisher component has the following properties, each of which is optional:

* `sessionId` (String) -- The OpenTok session ID. This is auto-populated by wrapping
   `OTPublisher` with `OTSession`, so you generally do not need to set this property for the OTPublisher.

* `properties` (Object) -- Options for the publisher instance. See the following section,
  [properties object](#properties-object). The `properties` object is used for initial set up
  of the Publisher. The `OTPublisher` object watches for changes on a few keys of the `properties` object,
  and makes the necessary changes. Currently these are:

  * cameraPosition -- Sets the camera to 'front' or 'back'.

  * publishAudio -- Toggles audio on (`true`) or off `false`.

  * publishVideo -- Toggles video on (`true`) or off `false`.

* `eventHandlers` (Object) -- An object containing key-value pairs of event names and
callback functions for event handlers. See [Events](#events).

## Methods

**getRtcStatsReport()** Gets the RTC stats report for the publisher. This is an asynchronous operation.
The OTPublisher object dispatches an `rtcStatsReport` event when RTC statistics for the publisher are available.

## properties object

The `properties` object passed into the OTPublisher object has the following properties:

**audioBitrate** (Number) -- The desired bitrate for the published audio, in bits per second. The supported range of values is 6,000 - 510,000. (Invalid values are ignored.) Set this value to enable high-quality audio (or to reduce bandwidth usage with lower-quality audio).
  
The following are recommended settings:

  * 8,000 - 12,000 for narrowband (NB) speech
  * 16,000 - 20,000 for wideband (WB) speech
  * 28,000 - 40,000 for full-band (FB) speech
  * 48,000 - 64,000 for full-band (FB) music
  * 64,000 - 128,000 for full-band (FB) stereo music
  
  The default value is 40,000.

**audioFallbackEnabled** (Boolean) —- Whether the stream will use the audio-fallback feature
(`true`) or not (`false`). The audio-fallback feature is available in sessions that use the
OpenTok Media Router. With the audio-fallback feature enabled (the default), when the OpenTok Media
Router determines that a stream's quality has degraded significantly for a specific subscriber,
it disables the video in that subscriber in order to preserve audio quality. For streams that use
a camera as a video source, the default setting is true (the audio-fallback feature is enabled).
The default setting is false (the audio-fallback feature is disabled) for screen-sharing streams,
which have the `videoSource` property set to "screen" in OTPublisher component. For more information,
see the Subscriber videoDisabled event and the OpenTok Media Router and media modes.

**audioTrack** (Boolean) -- If this property is set to false, the audio subsystem will not be initialized for the publisher, and setting the `publishAudio` property will have no effect. If your application does not require the use of audio, it is recommended to set this property rather than use the publishAudio property, which only temporarily disables the audio track.

* **cameraPosition** (String) -- The preferred camera position. When setting this property, if the change is possible, the publisher will use the camera with the specified position. Valid inputs are 'front' (the default) and 'back'.

* **enableDtx** (Boolean) - Whether to enable [Opus DTX](https://datatracker.ietf.org/doc/html/rfc7587#section-3.1.3). The default value is `false`. Setting this to true can reduce bandwidth usage in streams that have long periods of silence.

* **frameRate** (Number) - The desired frame rate, in frames per second, of the video. Valid values are 30, 15, 7, and 1. The published stream will use the closest value supported on the publishing client. The frame rate can differ slightly from the value you set, depending on the device of the client. And the video will only use the desired frame rate if the client configuration supports it. 

* **name** (String) -- A string that will be associated with this publisher’s stream. This string is displayed at the bottom of publisher videos and at the bottom of subscriber videos associated with the published stream. If you do not specify a value, the name is set to the device name.

* **publishAudio** (Boolean) -- Whether to publish audio. The default is `true`.

* **publishVideo** (Boolean) -- Whether to publish video. The default is `true`.

* **scalableScreenshare** (Boolean) -- Whether to allow use of
{scalable video}(https://tokbox.com/developer/guides/scalable-video/) for a screen-sharing publisher
(true) or not (false, the default). This only applies to a publisher that has the `videoSource` set
to "screen".

* **resolution** (String) - The desired resolution of the video. The format of the string is "widthxheight", where the width and height are represented in pixels. Valid values are "1920x1080", "1280x720", "640x480", and "352x288". The published video will only use the desired resolution if the client configuration supports it. Some devices and clients do not support each of these resolution settings.

* **videoContentHint** (String) -- Sets the content hint of the video track of the publisher's stream. You can set this to one of the following values: "", "motion", "details" or "text". For additional information, see the [documentation](https://tokbox.com/developer/sdks/js/reference/OT.html#initPublisher) for the `videoContentHint` option of the
`OT.initPublisher()` method of the OpenTok.js SDK.

* **videoTrack** (Boolean) -- If this property is set to false, the video subsystem will not be initialized for the publisher, and setting the publishVideo property will have no effect. If your application does not require the use of video, it is recommended to set this property rather than use the publishVideo property, which only temporarily disables the video track.

* **videoSource** (String) -- To publish a screen-sharing stream, set this property to "screen". If you do not specify a value, this will default to "camera".

## Events

* **audioLevel** (Number) -- The audio level, from 0 to 1.0. Adjust this value logarithmically for use in adjusting a user interface element, such as a volume meter. Use a moving average to smooth the data.

* **audioNetworkStats** (Object) — Sent periodically to report audio statistics for the publisher.
  A [PublisherAudioNetworkStatsEvent](./EventData.md#PublisherAudioNetworkStatsEvent) object is passed into the event handler.

* **error** (Object) -- Sent if the publisher encounters an error. After this message is sent, the publisher can be considered fully detached from a session and may be released.

* **muteForced** -- Sent when a moderator has forced this client to mute audio. 

* **otrnError** (Object) -- Sent if there is an error with the communication between the native publisher instance and the JS component.

* **rtcStatsReport** (Object) -- Sent when RTC stats reports are available for the publisher,
  in response to calling the `OTPublisher.getRtcStatsReport()` method. A
  [PublisherRtcStatsReportEvent](./EventData.md#publisherRtcStatsReportEvent) object is passed into
  the event handler. This event has an array of
  objects. For a routed session (a seesion that uses the
  [OpenTok Media Router](https://tokbox.com/developer/guides/create-session/#media-mode)),
  this array includes one object, defining the statistics for the single video media stream that is sent
  to the OpenTok Media Router. In a relayed session, the array includes an object for each subscriber
  to the published stream. Each object includes two properties:

  * `connectionId` -- For a relayed session (in which a publisher sends individual media streams
    to each subscriber), this is the unique ID of the client’s connection.

  * `jsonArrayOfReports` -- A JSON array of RTC stats reports for the media stream. The structure
  of the JSON array is similar to the format of the RtcStatsReport object implemented in web browsers
  (see the [Mozilla docs](https://developer.mozilla.org/en-US/docs/Web/API/RTCStatsReport)).
  Also see [this W3C documentation](https://w3c.github.io/webrtc-stats/).

* **streamCreated** (Object) -- Sent when the publisher starts streaming.
A [streamingEvent](./EventData.md#streamingEvent) object is passed into the event handler.

* **streamDestroyed** (Object) -- Sent when the publisher stops streaming.
A [streamingEvent](./EventData.md#streamingEvent) object is passed into the event handler.

**videoNetworkStats** (Object) -- Sent periodically to report audio statistics for the publisher.
  A [PublisherVideoNetworkStatsEvent](./EventData.md#PublisherVideoNetworkStatsEvent) object is passed into the event handler.
