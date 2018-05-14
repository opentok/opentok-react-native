![OpenTok Labs](https://d26dzxoao6i3hh.cloudfront.net/items/0U1R0a0e2g1E361H0x3c/Image%202017-11-22%20at%2012.16.38%20PM.png?v=2507a2df)
# opentok-react-native

- [Pre-Requisites](#pre-requisites)
- [Installation](#installation)
  - [iOS Installation](#ios-installation)
  - [Android Installation](#android-installation)
- API Reference
  - [OTSession Component](https://github.com/opentok/opentok-react-native/tree/master/docs/OTSession.md)
  - [OTPublisher Component](https://github.com/opentok/opentok-react-native/tree/master/docs/OTPublisher.md)
  - [OTSubscriber Component](https://github.com/opentok/opentok-react-native/tree/master/docs/OTSubscriber.md)
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
  * `OTScreenCapturer.swift`

9. Click `Create Bridging Header` when you're prompted with the following modal: `Would you like to configure an Objective-C bridging header?`

10. Add the contents from the `Bridging-Header.h` file in `../node_modules/opentok-react-native/ios` to `<YourProjectName>-Bridging-Header.h`

11. Ensure you have enabled both camera and microphone usage by adding the following entries to your `Info.plist` file:

```
<key>NSCameraUsageDescription</key>
<string>Your message to user when the camera is accessed for the first time</string>
<key>NSMicrophoneUsageDescription</key>
<string>Your message to user when the microphone is accessed for the first time</string>
```

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

7. As for the older Android devices, ensure you add camera and audio permissions to your `AndroidManifest.xml` file:

```xml
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-feature android:name="android.hardware.camera" android:required="true" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
    <uses-feature android:name="android.hardware.microphone" android:required="true" />
```

Newer versions of Android–`API Level 23` (Android 6.0)–have a different permissions model that is already handled by this library.

## Contributing

If you make changes to the project that you would like to contribute back then please follow the [contributing guidelines](CONTRIBUTING.md). All contributions are greatly appreciated!
