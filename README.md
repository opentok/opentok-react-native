# Vonage Video client SDK for React Native

<img src="https://assets.tokbox.com/img/vonage/Vonage_VideoAPI_black.svg" height="48px" alt="Tokbox is now known as Vonage" />

React Native library for using the [Vonage Video API](https://developer.vonage.com/en/video/overview).

This library is now officially supported by Vonage.

**Important:** This version is a beta build of the Vonage Video React Native SDK with support for the [React Native new architecture](https://reactnative.dev/architecture/landing-page). Be sure to read the next section ("Beta version notes") for important details on using this beta version.

The only difference from previous versions is that you need to use a version of React Native that supports the new architecture (0.76+) and you need to register the OpenTok React Native packages in your application:

* For Android, register the `OpentokReactNativePackage`, `OTRNPublisherPackage`, and `OTRNSubscriberPackage` packages in the MainActivity file for your app. See step 6 of the "Android Installation" section below.

* For iOS, register the `OTRNPublisherPackage` and `OTRNSubscriberPackage` packages in the AppDelegate file for your app. See step 4 of the "iOS Installation" section below.

## Prerequisites

1. Install [node.js](https://nodejs.org/)

2. Install and update [Xcode](https://developer.apple.com/xcode/) (you will need a Mac). (See the React Native iOS installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html).)

3. Install and update [Android Studio](https://developer.android.com/studio/index.html). (See the React Native Android installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html).)

## System requirements

See the system requirements for the [Vonage Video Android SDK](https://developer.vonage.com/en/video/client-sdks/android/overview) and [Vonage Video iOS SDK](https://developer.vonage.com/en/video/client-sdks/ios/overview). The Vonage Video React Native SDK has the same requirements for Android and iOS.

## Installation

### For Expo projects

If you're using Expo, the setup is simplified with the config plugin:

1. Install the package:

   ```bash
   npx expo install @vonage/client-sdk-video-react-native
   ```

2. Add the plugin to your `app.json` or `app.config.js`:

   ```json
   {
     "expo": {
       "plugins": [
         [
           "@vonage/client-sdk-video-react-native",
           {
             "cameraPermission": "Allow $(PRODUCT_NAME) to use your camera for video calls",
             "microphonePermission": "Allow $(PRODUCT_NAME) to use your microphone for audio calls"
           }
         ]
       ]
     }
   }
   ```

   **Plugin iOS Configuration Options:**

   | Option                 | Type   | Default                                                             | Description                                                      |
   | ---------------------- | ------ | ------------------------------------------------------------------- | ---------------------------------------------------------------- |
   | `cameraPermission`     | string | `"Allow $(PRODUCT_NAME) to access your camera for video calls"`     | iOS camera permission message (NSCameraUsageDescription)         |
   | `microphonePermission` | string | `"Allow $(PRODUCT_NAME) to access your microphone for audio calls"` | iOS microphone permission message (NSMicrophoneUsageDescription) |

3. Rebuild your app:

   ```bash
   npx expo prebuild
   npx expo run:ios
   # or
   npx expo run:android
   ```

**What the config plugin does automatically:**

- ✅ Adds iOS camera and microphone permissions to Info.plist
- ✅ Adds all required Android permissions to AndroidManifest.xml:
  - BLUETOOTH
  - REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
  - BLUETOOTH_CONNECT
  - BROADCAST_STICKY
  - CAMERA
  - INTERNET
  - MODIFY_AUDIO_SETTINGS
  - READ_PHONE_STATE
  - RECORD_AUDIO
  - ACCESS_NETWORK_STATE
- ✅ Configures hardware features for Android

**No manual native configuration needed!**

---

### For React Native CLI projects

1. In your terminal, change into your React Native project's directory.

2. Add the beta versioin of the library using `npm` or `yarn`:

  * `npm install @vonage/client-sdk-video-react-native@<VERSION>`
  * `yarn add @vonage/client-sdk-video-react-native@<VERSION>`
  
Note: Replace `<VERSION>` with the target version to use.

### iOS Installation

1. Install the iOS pods:

   ```
   cd ios;
   bundle exec pod install
   ```

2. Ensure you have enabled both camera and microphone usage by adding the following entries to the `Info.plist` file:

   ```
   <key>NSCameraUsageDescription</key>
   <string>Your message to user when the camera is accessed for the first time</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Your message to user when the microphone is accessed for the first time</string>
   ```

  When you create an archive of your app, the [privacy manifest settings required by Apple's App store](https://developer.apple.com/support/third-party-SDK-requirements) are added automatically with this version of the Vonage Video React Native SDK.

3. Register the OpenTok OTRNPublisher and OTRNSubscriber classes. Do this by modifying the AppDelegate implementation.

   * If you app has an Objective-C++ AppDelegate file (AppDelegate.mm), add these classes to the list of packages in the NSMutableDictionary returned by the `thirdPartyFabricComponents()` function:

    <pre>
        #import "OTRNPublisherComponentView.h"
        #import "OTRNSubscriberComponentView.h"

        @implementation AppDelegate
     
            // ...
     
            - (NSDictionary<NSString *,Class<RCTComponentViewProtocol>> *)thirdPartyFabricComponents
            {
              NSMutableDictionary * dictionary = [super thirdPartyFabricComponents].mutableCopy;
              dictionary[@"OTRNPublisher"] = [OTRNPublisherComponentView class];
              dictionary[@"OTRNSubscriber"] = [OTRNSubscriberComponentView class];
              return dictionary;
            }
        
        @end
    </pre>

   * If your app uses a Swift AppDelegate file (AppDelegate.swift), you will need to have its implementation of the `RCTAppDelegate.application(_, didFinishLaunchingWithOptions)` method use a bridging header to call a method in an Objective-C++ file that calls the `[RCTComponentViewFactory registerComponentViewClass:]` method, passing in the `OTRNPublisherComponentView` and `OTRNSubscriberComponentView` classes.

     For example, add a bridging header for your app:

     <pre>
     #ifndef BasicVideoTS_Bridging_Header_h
     #define BasicVideoTS_Bridging_Header_h
     
     #import "FabricComponentRegistrar.h"
     
     #endif
     </pre>
     
     Then create `FabricComponentRegistrar.h` and `FabricComponentRegistrar.cpp` files:
     
     <pre>
     // FabricComponentRegistrar.hpp
     
     #import <Foundation/Foundation.h>
     
     @interface FabricComponentRegistrar : NSObject
     + (void)registerCustomComponents;
     @end
     </pre>
     
     <pre>
     //  FabricComponentRegistrar.mm
     #include "FabricComponentRegistrar.h"
     #import <React/RCTComponentViewFactory.h>
     #import <React/RCTViewComponentView.h>
     #import "OTRNPublisherComponentView.h"
     #import "OTRNSubscriberComponentView.h"
     
     @implementation FabricComponentRegistrar
     
     + (void)registerCustomComponents {
         RCTComponentViewFactory *factory = [RCTComponentViewFactory currentComponentViewFactory];
         [factory registerComponentViewClass:[OTRNPublisherComponentView class]];
         [factory registerComponentViewClass:[OTRNSubscriberComponentView class]];
     }
     </pre>
     
     Finally, call the `FabricComponentRegistrar.registerCustomComponents()` method in the AppDelegate.swift `RCTAppDelegate.application(_, didFinishLaunchingWithOptions)` method:
     
     <pre>
     override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
         self.moduleName = "BasicVideoTS"
         self.dependencyProvider = RCTAppDependencyProvider()

         // You can add your custom initial props in the dictionary below.
         // They will be passed down to the ViewController used by React Native.
         self.initialProps = [:]
     
     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        FabricComponentRegistrar.registerCustomComponents()
        return result
     }
     </pre>
   
   Register the FabricComponentRegistrar.mm file as a build file in XCode.

4. If your app will use the `OTPublisher.setVideoTransformers()` or `OTPublisher.setAudioTransformers()` method, you need to include the following in your Podfile:

   ```
   pod 'VonageClientSDKVideoTransformers', '= <VERSION>'
   ```

Note: Replace `<VERSION>` with the iOS Client SDK version.

If you try to archive the app and it fails, please do the following:

1. Go to *Target*.

2. Click *Build Phases*.

3. Under the *Link Binary With Libraries* section, remove `libOpenTokReactNative.a` and add it again.

### Android Installation

1. In your terminal, change into your project directory.

2. Run `bundle install`.

3. Make sure the following in your app's gradle `compileSdkVersion`, `buildToolsVersion`, `minSdkVersion`, and `targetSdkVersion` are greater than or equal to versions specified in the Vonage Video React library.

4. The SDK automatically adds Android permissions it requires. You do not need to add these to your app manifest. However, certain permissions require you to prompt the user. See the [full list of required permissions](https://developer.vonage.com/en/video/client-sdks/android/overview#permissions) in the Vonage Video API Android SDK documentation.

5. In the MainApplication.kt file for your app, register the OpenTok OpentokReactNativePackage, OTRNPublisherPackage, and OTRNSubscriberPackage packages. Do this by modifying the MainApplication file by adding these to the list of packages returned by the `getPackages()` function:

    ```
    import com.opentokreactnative.OTRNPublisherPackage
    import com.opentokreactnative.OTRNSubscriberPackage
    import com.opentokreactnative.OpentokReactNativePackage;

    // ...

    override fun getPackages(): List<ReactPackage> =
        PackageList(this).packages.apply {
            add(OTRNPublisherPackage())
            add(OTRNSubscriberPackage())
            add(OpentokReactNativePackage())
        }
        // ...
    ```

7. If your app will use the `OTPublisher.setVideoTransformers()` or `OTPublisher.setAudioTransformers()` method, you need to include the following in your app/build.gradle file:

   ```
   implementation "com.vonage:client-sdk-video-transformers:<VERSION>"
   ```

Note: Replace `<VERSION>` with the Android Client SDK version.

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

To see this library in action, check out the [vonage-video-react-native-sdk-samples](https://github.com/Vonage/vonage-video-react-native-sdk-samples) repo. 

## Development and Contributing

Interested in contributing? We :heart: pull requests! See the
[Contribution](CONTRIBUTING.md) guidelines.

## Getting Help

We love to hear from you so if you have questions, comments or find a bug in the project, let us know! You can either:

- Open an issue on this repository
- See <https://api.support.vonage.com/hc/en-us/> for support options
- Tweet at us! We're [@VonageDev](https://twitter.com/VonageDev) on Twitter
- Or [join the Vonage Developer Community Slack](https://developer.nexmo.com/community/slack)
