![OpenTok Labs](https://d26dzxoao6i3hh.cloudfront.net/items/0U1R0a0e2g1E361H0x3c/Image%202017-11-22%20at%2012.16.38%20PM.png?v=2507a2df)
# opentok-react-native

- [Pre-Requisites](#pre-requisites)
- [Installation](#installation)
  - [iOS Installation](#ios-installation)
  - [Android Installation](#android-installation)
- [API Reference](#api-reference)
  - [OTSession Component](#otsession-component)
  - [OTPublisher Component](#otpublisher-component)
  - [OTSubscriber Component](#otsubscriber-component)
- [Contributing](#contributing)

### In this repo, you'll find the OpenTok React Native library:

## Pre-Requisites:

1. Install [node.js](https://nodejs.org/)

2. Install and update [Xcode](https://developer.apple.com/xcode/) (you will need a Mac)
* React Native iOS installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html)

3. Install and update [Android Studio](https://developer.android.com/studio/index.html)
* React Native Android installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html)

## Installation:

1. In your terminal, change into your React Native project's directory

2. In your terminal, run `npm install opentok-react-native`

### iOS Installation

**Note** Please make sure to have [CocoaPods](https://cocoapods.org/) on your computer.
1. In you terminal, change into your `ios` directory.

2. Create a pod file by running: `pod init`.

3. Add the following to your pod file:

```
    platform :ios, '9.0'

    target '<YourProjectName>' do
      use_frameworks!

      # Pods for <YourProject>
        pod 'OpenTok'
    end

```

4. Now run, `pod install`

5. Open XCode

6. Open `<YourProjectName>.xcworkspace` file in XCode. This file can be found in the `ios` folder of your React Native project. 

7. Click `File` and `Add Files to`

8. Add the following files from `../node_modules/opentok-react-native/ios` to the project:
  * `OTPublisher.h`
  * `OTPublisher.m`
  * `OTPublisherManager.swift`
  * `OTPublisherView.swift`
  * `OTRN.swift`
  * `OTSessionManager.m`
  * `OTSessionManager.swift`
  * `OTSubscriber.h`
  * `OTSubscriber.m`
  * `OTSubscriberManager.swift`
  * `OTSubscriberView.swift`

9. Click `Create Bridging Header` when you're prompted with the following modal: `Would you like to configure an Objective-C bridging header?`

10. Add the contents from the `Bridging-Header.h` file in `../node_modules/opentok-react-native/ios` to `<YourProjectName>-Bridging-Header.h`

### Android Installation

1. In you terminal, change into your project directory.

2. Run `react-native link opentok-react-native`

3. Open your Android project in Android Studio.

4. Add the following to your project `build.gradle` file: 

```
        maven {
            url "http://tokbox.bintray.com/maven"
        }
```
* It should look something like this:
* ![](https://dha4w82d62smt.cloudfront.net/items/1W1p0Z27471J210d3M2r/Image%202018-03-08%20at%202.12.38%20PM.png?X-CloudApp-Visitor-Id=2816462&v=8ce583bb)

5. Sync Gradle

6. Make sure the following in your app's gradle `compileSdkVersion`, `buildToolsVersion`, `minSdkVersion`, and `targetSdkVersion` are the same in the OpenTok React Native library.

## API Reference

The `OpenTok React Native` library comprises of:

- `OTSession` Component
- `OTPublisher` Component
- `OTSubscriber` Component

### OTSession Component

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| apiKey | String | Yes | TokBox API Key
| sessionId | String | Yes | TokBox Session ID
| token | String | Yes | TokBox token
| signal | Object | No | Used to send a signal to the session
| eventHandlers | Object&lt;Function&gt; | No | Event handlers passed into the native session instance.

The `OTSession` component manages the connection to an OpenTok Session. It passes the sessionId to the `sessionId` prop to its child components. To disconnect the session, unmount the `OTSession` component. To publish and subscribe, you must nest `OTPublisher` and `OTSubscriber` inside `OTSession`:


```html
<OTSession apiKey="your-api-key" sessionId="your-session-id" token="your-session-token">
  <OTPublisher style={{ width: 100, height: 100 }}/>
  <OTSubscriber style={{ width: 100, height: 100 }} />
</OTSession>
```

### OTPublisher Component

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| sessionId | String | No | OpenTok sessionId. This is auto populated by wrapping `OTPublisher` with `OTSession`
| properties | Object | No | Properties passed into the native publisher instance
| eventHandlers | Object&lt;Function&gt; | No | Event handlers passed into native publsiher instance

* **Properties** 
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

  * **resolution** (String) - The desired resolution of the video. The format of the string is "widthxheight", where the width and height are represented in pixels. Valid values are "1280x720", "640x480", and "320x240". The published video will only use the desired resolution if the client configuration supports it. Some devices and clients do not support each of these resolution settings.

  * **videoTrack** (Boolean) — If this property is set to false, the video subsystem will not be initialized for the publisher, and setting the publishVideo property will have no effect. If your application does not require the use of video, it is recommended to set this property rather than use the publishVideo property, which only temporarily disables the video track.



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
| publishAudio | Calls OT.publishAudio() to toggle audio on and off |
| publishVideo | Calls OT.publishVideo() to toggle video on and off |

Please keep in mind that `OT` is not the same as `OT` in the JS SDK, the `OT` in this library refers to the iOS and Android `OTSessionManager` class.

### OTSubscriber Component

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| sessionId | String | No | OpenTok Session Id. This is auto populated by wrapping `OTSubscriber` with `OTSession`
| streamId | String| No | OpenTok Subscriber streamId. This is auto populated inside the `OTSubscriber` component when `streamCreated` event is fired from the native session delegate(iOS)/ interface(Android)
| properties | Object | No | Properties passed into the native subscriber instance
| eventHandlers | Object&lt;Function&gt; | No | Event handlers passed into the native subscriber instance

* **Properties** 
  * **subscribeToAudio** (Boolean) — Whether to subscribe to audio.

  * **subscribeToVideo** (Boolean) — Whether to subscribe video.


The `OTSubscriber` component will subscribe to a specified stream from a specified session upon mounting. The `OTSubscriber` component will stop subscribing and unsubscribing when it's unmounting.

## Contributing

If you make changes to the project that you would like to contribute back then please follow the [contributing guidelines](CONTRIBUTING.md). All contributions are greatly appreciated!