# opentok-react-native

<img src="https://assets.tokbox.com/img/vonage/Vonage_VideoAPI_black.svg" height="48px" alt="Tokbox is now known as Vonage" />

React Native library for using [OpenTok](https://tokbox.com/developer/).

This library is now officially supported by Vonage.

In this repo, you'll find the OpenTok React Native library.

## Prerequisites

1. Install [node.js](https://nodejs.org/)

2. Install and update [Xcode](https://developer.apple.com/xcode/) (you will need a Mac). (See the React Native iOS installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html).)

3. Install and update [Android Studio](https://developer.android.com/studio/index.html). (See the React Native Android installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html).)

## System requirements

See the system requirements for the [OpenTok Android SDK](https://tokbox.com/developer/sdks/android/#requirements) and [OpenTok iOS SDK](https://tokbox.com/developer/sdks/ios/#system-requirements). (The OpenTok React Native SDK has the same requirements for Android and iOS.)

## Installation

1. In your terminal, change into your React Native project's directory.

2. Add the library using `npm` or `yarn`:

- `npm install opentok-react-native`
- `yarn add opentok-react-native`

### iOS Installation

1. Install the iOS pods:

   ```
   npx pod-install
   ```

2. **For React Native versions prior to 0.60**:
   - Add this to your Podfile:

     ```
     target '<YourProjectName>' do
         # Pods for <YourProject>
         pod 'OTXCFramework', '2.29.1'
     end
     ```

   - Run `react-native link opentok-react-native`.

   These steps are not necessary in React Native version 0.60 and later.

3. Ensure you have enabled both camera and microphone usage by adding the following entries to the `Info.plist` file:

   ```
   <key>NSCameraUsageDescription</key>
   <string>Your message to user when the camera is accessed for the first time</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Your message to user when the microphone is accessed for the first time</string>
   ```

When you create an archive of your app, the [privacy manifest settings required by Apple's App store](https://developer.apple.com/support/third-party-SDK-requirements) are added automatically with this version of the OpenTok React Native SDK.

3. If your app will use the `OTPublisher.setVideoTransformers()` or `OTPublisher.setAudioTransformers()` method, you need to include the following in your Podfile:

   ```
   pod 'VonageClientSDKVideoTransformers'
   ```

If you try to archive the app and it fails, please do the following:

1. Go to _Target_.

2. Click _Build Phases_.

3. Under the _Link Binary With Libraries_ section, remove `libOpenTokReactNative.a` and add it again.

### Android Installation

1. In your terminal, change into your project directory.

2. **For React Native versions prior to 0.60**:
   - Run `react-native link opentok-react-native`

   This step is not necessary in React Native version 0.60 and later.

3. Run `bundle install`.

4. Make sure the following in your app's gradle `compileSdkVersion`, `buildToolsVersion`, `minSdkVersion`, and `targetSdkVersion` are greater than or equal to versions specified in the OpenTok React Native library.

5. The SDK automatically adds Android permissions it requires. You do not need to add these to your app manifest. However, certain permissions require you to prompt the user. See the [full list of required permissions](https://tokbox.com/developer/sdks/android/#permissions) in the Vonage Video API Android SDK documentation.

6. If your app will use the `OTPublisher.setVideoTransformers()` or `OTPublisher.setAudioTransformers()` method, you need to include the following in your app/build.gradle file:

   ```
   implementation "com.vonage:client-sdk-video-transformers:2.30.1"
   ```

#### Bintray sunset

Bintray support has ended (official announcement: [https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/](https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/)). In your app build.gradle file you need to remove reference to `jcenter` and replace it with `mavenCentral`. Example:

```
// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    ...
    repositories {
        google()
        mavenCentral()
    }
    ...
}

allprojects {
    repositories {
        maven {
            // All of React Native (JS, Obj-C sources, Android binaries) is installed from npm
            url("$rootDir/../node_modules/react-native/android")
        }
        maven {
            // Android JSC is installed from npm
            url("$rootDir/../node_modules/jsc-android/dist")
        }
        mavenCentral {
            // We don't want to fetch react-native from Maven Central as there are
            // older versions over there.
            content {
                excludeGroup "com.facebook.react"
            }
        }
        google()
        maven { url 'https://www.jitpack.io' }
    }
}
```

## Docs

See the [docs](https://tokbox.com/developer/sdks/react-native/reference).

## Samples

To see this library in action, check out the [opentok-react-native-samples](https://github.com/opentok/opentok-react-native-samples) repo.

## Development and Contributing

Interested in contributing? We :heart: pull requests! See the
[Contribution](CONTRIBUTING.md) guidelines.

## Getting Help

We love to hear from you so if you have questions, comments or find a bug in the project, let us know! You can either:

- Open an issue on this repository
- See <https://support.tokbox.com/> for support options
- Tweet at us! We're [@VonageDev](https://twitter.com/VonageDev) on Twitter
- Or [join the Vonage Developer Community Slack](https://developer.nexmo.com/community/slack)
