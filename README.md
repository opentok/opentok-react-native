# opentok-react-native

<img src="https://assets.tokbox.com/img/vonage/Vonage_VideoAPI_black.svg" height="48px" alt="Tokbox is now known as Vonage" />

## Please note that this library is not officially supported by Vonage.
React Native library for OpenTok iOS and Android SDKs

- [opentok-react-native](#opentok-react-native)
  - [Please note that this library is not officially supported by Vonage.](#please-note-that-this-library-is-not-officially-supported-by-vonage)
    - [In this repo, you'll find the OpenTok React Native library:](#in-this-repo-youll-find-the-opentok-react-native-library)
  - [Pre-Requisites:](#pre-requisites)
  - [Installation:](#installation)
    - [iOS Installation](#ios-installation)
    - [Android Installation](#android-installation)
      - [Bintray sunset](#bintray-sunset)
  - [Samples](#samples)
  - [Development and Contributing](#development-and-contributing)
  - [Getting Help](#getting-help)

### In this repo, you'll find the OpenTok React Native library:

## Pre-Requisites:

1. Install [node.js](https://nodejs.org/)

2. Install and update [Xcode](https://developer.apple.com/xcode/) (you will need a Mac)

- React Native iOS installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html)

3. Install and update [Android Studio](https://developer.android.com/studio/index.html)

- React Native Android installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html)

## Installation:

1. In your terminal, change into your React Native project's directory

2. Add the library using `npm` or `yarn`.

- `npm install opentok-react-native`
- `yarn add opentok-react-native`

### iOS Installation

**Note:** Please make sure to have [CocoaPods](https://cocoapods.org/) on your computer.
If you've installed this package before, you may need to edit your `Podfile` and project structure because the installation process has changed.

1. In you terminal, change into the `ios` directory of your React Native project.

2. Create a pod file by running: `pod init`.

**For React Native < 0.60**, add this to your Podfile:

```
    target '<YourProjectName>' do

      # Pods for <YourProject>
        pod 'OpenTok', '2.20.0'
    end

```

3. Now run, `pod install`

4. After installing the OpenTok iOS SDK, change into your root directory of your project.

**For React Native < 0.60**, now run `react-native link opentok-react-native`.

5. Open `<YourProjectName>.xcworkspace` contents in XCode. This file can be found in the `ios` folder of your React Native project.

6. Click `File` and `New File`

7. Add an empty swift file to your project:

   - You can name this file anything i.e: `OTInstall.swift`. This is done to set some flags in XCode so the Swift code can be used.

8. Click `Create Bridging Header` when you're prompted with the following modal: `Would you like to configure an Objective-C bridging header?`

9. Ensure you have enabled both camera and microphone usage by adding the following entries to your `Info.plist` file:

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

   - Run `react-native link opentok-react-native`

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
