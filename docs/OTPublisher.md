### OTPublisher Component

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| sessionId | String | No | OpenTok sessionId. This is auto populated by wrapping `OTPublisher` with `OTSession`
| properties | Object | No | Properties passed into the native publisher instance
| eventHandlers | Object&lt;Function&gt; | No | Event handlers passed into native publsiher instance

## Properties
  * **audioBitrate** (Number) — The desired bitrate for the published audio, in bits per second. The supported range of values is 6,000 - 510,000. (Invalid values are ignored.) Set this value to enable high-quality audio (or to reduce bandwidth usage with lower-quality audio).
  The following are recommended settings:

    * **8,000 - 12,000 for narrowband (NB) speech**
    * **16,000 - 20,000 for wideband (WB) speech**
    * **28,000 - 40,000 for full-band (FB) speech**
    * **48,000 - 64,000 for full-band (FB) music**
    * **64,000 - 128,000 for full-band (FB) stereo music**
    
    * **The default value is 40,000.**

  * **audioFallbackEnabled** (Boolean) — Whether to turn on audio fallback or not.

  * **audioTrack** (Boolean) — If this property is set to false, the audio subsystem will not be initialized for the publisher, and setting the publishAudio property will have no effect. If your application does not require the use of audio, it is recommended to set this property rather than use the publishAudio property, which only temporarily disables the audio track.

  * **cameraPosition** (String) - The preferred camera position. When setting this property, if the change is possible, the publisher will use the camera with the specified position. Valid Inputs: 'front' or 'back'
  
  * **frameRate** (Number) - The desired frame rate, in frames per second, of the video. Valid values are 30, 15, 7, and 1. The published stream will use the closest value supported on the publishing client. The frame rate can differ slightly from the value you set, depending on the device of the client. And the video will only use the desired frame rate if the client configuration supports it. 

  * **name** (String) — A string that will be associated with this publisher’s stream. This string is displayed at the bottom of publisher videos and at the bottom of subscriber videos associated with the published stream. If you do not specify a value, the name is set to the device name.

  * **publishAudio** (Boolean) — Whether to publish audio.

  * **publishVideo** (Boolean) — Whether to publish video.

  * **resolution** (String) - The desired resolution of the video. The format of the string is "widthxheight", where the width and height are represented in pixels. Valid values are "1280x720", "640x480", and "352x288". The published video will only use the desired resolution if the client configuration supports it. Some devices and clients do not support each of these resolution settings.

  * **videoTrack** (Boolean) — If this property is set to false, the video subsystem will not be initialized for the publisher, and setting the publishVideo property will have no effect. If your application does not require the use of video, it is recommended to set this property rather than use the publishVideo property, which only temporarily disables the video track.

  * **videoSource** (String) — To publish a screen-sharing stream, set this property to "screen". If you do not specify a value, this will default to "camera".


The `OTPublisher` component will initialize a publisher and publish to the specified session upon mounting. To destroy the publisher, unmount the `OTPublisher` component. Please keep in mind that the publisher view is not removed unless you specifically unmount the `OTPublisher` component.

```html
<OTSession apiKey="your-api-key" sessionId="your-session-id" token="your-session-token">
  <OTPublisher style={{ width: 100, height: 100 }} />
</OTSession>
```
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

The `properties` prop is used for initial set up of the Publisher and making changes to it will update the Publisher. For convenience the `OTPublisher` watches for changes on a few keys of the `properties` object and makes the necessary changes. Currently these are:

| Publisher Property | Action |
| --- | --- |
| cameraPosition | Calls OT.changeCameraPosition() to toggle the camera |
| publishAudio | Calls OT.publishAudio() to toggle audio on and off |
| publishVideo | Calls OT.publishVideo() to toggle video on and off |

Please keep in mind that `OT` is not the same as `OT` in the JS SDK, the `OT` in this library refers to the iOS and Android `OTSessionManager` class.

## Events
  * **audioLevel** (Number) — The audio level, from 0 to 1.0. Adjust this value logarithmically for use in adjusting a user interface element, such as a volume meter. Use a moving average to smooth the data.

  * **error** (Object) — Sent if the publisher encounters an error. After this message is sent, the publisher can be considered fully detached from a session and may be released.

  * **streamCreated** (Object) — Sent when the publisher starts streaming.

  * **streamDestroyed** (Object) - Sent when the publisher stops streaming.