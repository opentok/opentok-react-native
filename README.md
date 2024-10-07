# Vonage Video client SDK for React Native

<img src="https://assets.tokbox.com/img/vonage/Vonage_VideoAPI_black.svg" height="48px" alt="Tokbox is now known as Vonage" />

React Native library for using the [Vonage Video API](https://developer.vonage.com/en/video/overview).

This library is now officially supported by Vonage.

## Prerequisites

1. Install [node.js](https://nodejs.org/)

2. Install and update [Xcode](https://developer.apple.com/xcode/) (you will need a Mac). (See the React Native iOS installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html).)

3. Install and update [Android Studio](https://developer.android.com/studio/index.html). (See the React Native Android installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html).)

## System requirements

See the system requirements for the [OpenTok Android SDK](https://tokbox.com/developer/sdks/android/#requirements) and [OpenTok iOS SDK](https://tokbox.com/developer/sdks/ios/#system-requirements). (The OpenTok React Native SDK has the same requirements for Android and iOS.)

## Installation

1. In your terminal, change into your React Native project's directory.

2. Add the library using `npm` or `yarn`:

- `npm install @vonage/client-sdk-video-react-native`
- `yarn add @vonage/client-sdk-video-react-native`

### iOS Installation

1. Install the iOS pods:

   ```
   npx pod-install
   ```

2. **For React Native versions prior to 0.60**:

   * Add this to your Podfile:

     ```
     target '<YourProjectName>' do
         # Pods for <YourProject>
         pod 'VonageClientSDKVideoMacOS', '2.28.2'
     end
     ```
   
   * Run `react-native link @vonage/client-sdk-video-react-native`.

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

1. Go to *Target*.

2. Click *Build Phases*.

3. Under the *Link Binary With Libraries* section, remove `libOpenTokReactNative.a` and add it again.

### Android Installation

1. In your terminal, change into your project directory.

2. **For React Native versions prior to 0.60**:

   - Run `react-native link @vonage/client-sdk-video-react-native`

   This step is not necessary in React Native version 0.60 and later.

3. Run `bundle install`.

4. Make sure the following in your app's gradle `compileSdkVersion`, `buildToolsVersion`, `minSdkVersion`, and `targetSdkVersion` are greater than or equal to versions specified in the Vonage Video React library.

5. For older Android devices, add the following permissions to the `AndroidManifest.xml` file:

   * `android.permission.BLUETOOTH` -- The default audio device supports
   Bluetooth audio. If your app does not use the default audio device and does not
   use Bluetooth, you can remove this permission.

   * `android.permission.BLUETOOTH_CONNECT` -- You need to enable this for API level 31 and above. If you want
   to use the Bluetooth device with Android SDK DefaultAudioDevice targeting API level 31 and above, please
   ask for runtime permissions in the app or enable the ("Nearby devices/Bluetooth") permission manually in
   the app settings.

   * `android.permission.BROADCAST_STICKY` -- We have determined that this is unused by
   the Vonage Video Android SDK, and we will remove this permission from an upcoming release.

   * `android.permission.CAMERA` -- If your app does not use the default video capturer
   and does not access the camera, you can remove this permission.

   * `android.permission.INTERNET` -- Required.

   * `android.permission.MODIFY_AUDIO_SETTINGS` -- If your app does not use the default audio
   device and does not access the microphone, you can remove this permission.

   * `android.permission.READ_PHONE_STATE` -- The Vonage Video Android SDK requests this permission in API level 22
   and lower, and 31 and above.

   * `android.permission.RECORD_AUDIO` -- If your app does not use the default audio
   device and does not access the microphone, you can remove this permission.

   For newer versions of Android — `API Level 23` (Android 6.0) and later — you do not need to add these to your app manifest. The Vonage Video React Native SDK adds them automatically. However, if you use Android 21+, certain permissions require you to prompt the user.

   Your app can remove any of these permissions that will not be required. See [this post](https://stackoverflow.com/a/31616472) and [this Android documentation](https://developer.android.com/studio/build/manifest-merge). For example, this removes the `android.permission.CAMERA` permission:

   ```
   <uses-permission android:name="android.permission.CAMERA" tools:node="remove"/>
   ```

3. If your app will use the `OTPublisher.setVideoTransformers()` or `OTPublisher.setAudioTransformers()` method, you need to include the following in your app/build.gradle file:

   ```
   implementation "com.vonage:client-sdk-video-transformers:2.28.0"
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

See the [docs](https://developer.vonage.com/en/video/client-sdks/react-native/overview?source=video).

## Samples

To see this library in action, check out the [opentok-react-native-samples](https://github.com/opentok/opentok-react-native-samples) repo. **Important:** These samples were written for the OpenTok version of the React Native client SDK for Vonage Video. You will need to modify references the sample apps to work with this version of the client SDK (@vonage/client-sdk-video-react-native) for use with Vonage applications:

* In the source code, change `opentok-react-native` references to `@vonage/client-sdk-video-react-native`.

* For the `apiKey` prop of the `OTSession` component, pass in a Vonage *application ID* (*not* an OpenTok API key or a Vonage API key).

## Development and Contributing

Interested in contributing? We :heart: pull requests! See the
[Contribution](CONTRIBUTING.md) guidelines.

## Getting Help

We love to hear from you so if you have questions, comments or find a bug in the project, let us know! You can either:

- Open an issue on this repository
- See <https://api.support.vonage.com/hc/en-us/> for support options
- Tweet at us! We're [@VonageDev](https://twitter.com/VonageDev) on Twitter
- Or [join the Vonage Developer Community Slack](https://developer.nexmo.com/community/slack)
