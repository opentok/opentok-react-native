# opentok-react-native
![OpenTok Labs](https://d26dzxoao6i3hh.cloudfront.net/items/0U1R0a0e2g1E361H0x3c/Image%202017-11-22%20at%2012.16.38%20PM.png?v=2507a2df)

React Native library for OpenTok iOS and Android SDKs

- [Pre-Requisites](#pre-requisites)
- [Installation](#installation)
  - [iOS Installation](#ios-installation)
  - [Android Installation](#android-installation)
- API Reference
  - [OTSession Component](https://github.com/opentok/opentok-react-native/tree/master/docs/OTSession.md)
  - [OTPublisher Component](https://github.com/opentok/opentok-react-native/tree/master/docs/OTPublisher.md)
  - [OTSubscriber Component](https://github.com/opentok/opentok-react-native/tree/master/docs/OTSubscriber.md)
  - [Event Data](https://github.com/opentok/opentok-react-native/tree/master/docs/EventData.md)
- [Samples](#samples)
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

2. Add the library using `npm` or `yarn`.
* `npm install opentok-react-native`
* `yarn add opentok-react-native`

### iOS Installation

**Note:** Please make sure to have [CocoaPods](https://cocoapods.org/) on your computer.
If you've installed this package before, you may need to edit your `Podfile` and project structure because the installation process has changed.
1. In you terminal, change into the `ios` directory of your React Native project.

2. Create a pod file by running: `pod init`.

3. Add the following to your pod file:

```
    target '<YourProjectName>' do

      # Pods for <YourProject>
        pod 'OpenTok', '2.16.1'
    end

```

4. Now run, `pod install`

5. After installing the OpenTok iOS SDK, change into your root directory of your project.

6. Now run, `react-native link opentok-react-native`.

7. Open `<YourProjectName>.xcworkspace` contents in XCode. This file can be found in the `ios` folder of your React Native project. 

7. Click `File` and `New File`

8. Add an empty swift file to your project:
    * You can name this file anything i.e: `OTInstall.swift`. This is done to set some flags in XCode so the Swift code can be used.

9. Click `Create Bridging Header` when you're prompted with the following modal: `Would you like to configure an Objective-C bridging header?`

10. Ensure you have enabled both camera and microphone usage by adding the following entries to your `Info.plist` file:

```
<key>NSCameraUsageDescription</key>
<string>Your message to user when the camera is accessed for the first time</string>
<key>NSMicrophoneUsageDescription</key>
<string>Your message to user when the microphone is accessed for the first time</string>
```

If you try to archive the app and it fails, please do the following:

1. Go to Target
2. Click on Build Phases
3. Under the Link Binary With Libraries section, remove the libOpenTokReactNative.a and add it again 

### Android Installation

1. In your terminal, change into your project directory.

2. If you have already run `react-native link opentok-react-native` for the iOS installation, please skip this step.
    *  Run `react-native link opentok-react-native`

3. Open your Android project in Android Studio.

4. Add the following to your project `build.gradle` file: 

```
        maven {
            url "http://tokbox.bintray.com/maven"
        }
```

5. Sync Gradle

6. Make sure the following in your app's gradle `compileSdkVersion`, `buildToolsVersion`, `minSdkVersion`, and `targetSdkVersion` are greater than or equal to versions specified in the OpenTok React Native library.

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

## Samples

To see this library in action, check out the [opentok-react-native-samples](https://github.com/opentok/opentok-react-native-samples) repo.

## Contributing

If you make changes to the project that you would like to contribute back then please follow the [contributing guidelines](CONTRIBUTING.md). All contributions are greatly appreciated!
