# opentok-react-native

<img src="https://assets.tokbox.com/img/vonage/Vonage_VideoAPI_black.svg" height="48px" alt="Tokbox is now known as Vonage" />

React Native library for using [OpenTok](https://tokbox.com/developer/).

This library is now officially supported by Vonage.

In this repo, you'll find the OpenTok React Native library.

**Important:** This version is a beta build of the OpenTok React Native SDK with support for the [React Native new architecture](https://reactnative.dev/architecture/landing-page). Be sure to read the next section ("Beta version notes") for important details on using this beta version.

## Beta version notes

This Beta version is only supported in the React Native new architecture. It is not supported in apps that use the old architecture.

This beta pre-release version is not intended for use in final production apps.

### Registering the OpenTok packages in your application

For Android, register the `OpentokReactNativePackage`, `OTPublisherViewNativePackage`, and `OTSubscriberViewNativePackage` packages in the MainActivity file for your app. See step 6 of the "Android Installation" section below.

For iOS, register the `OpentokReactNativePackage`, `OTPublisherViewNativePackage`, and `OTSubscriberViewNativePackage` packages in the MainActivity file for your app. See step 4 of the "iOS Installation" section below.

### Known issues

The following are known issues in this beta version:

* Subscriber video freezes frequently when using VP9 or H264.
* `otrnError` events are missing.

## Prerequisites

1. Install [node.js](https://nodejs.org/)

2. Install and update [Xcode](https://developer.apple.com/xcode/) (you will need a Mac). (See the React Native iOS installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html).)

3. Install and update [Android Studio](https://developer.android.com/studio/index.html). (See the React Native Android installation [instructions](https://facebook.github.io/react-native/docs/getting-started.html).)

## System requirements

See the system requirements for the [OpenTok Android SDK](https://tokbox.com/developer/sdks/android/#requirements) and [OpenTok iOS SDK](https://tokbox.com/developer/sdks/ios/#system-requirements). (The OpenTok React Native SDK has the same requirements for Android and iOS.)

## Installation

1. In your terminal, change into your React Native project's directory.

2. Add the beta versioin of the library using `npm` or `yarn`:

  * `npm install opentok-react-native@2.31.0-beta.0`
  * `yarn add opentok-react-native@2.31.0-beta.0`

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
         pod 'OTXCFramework', '2.30.1'
     end
     ```
   
   * Run `react-native link opentok-react-native`.

   These steps are not necessary in React Native version 0.60 and later.

3. Ensure you have enabled both camera and microphone usage by adding the following entries to the `Info.plist` file:

   ```
   <key>NSCameraUsageDescription</key>
   <string>Your message to user when the camera is accessed for the first time</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Your message to user when the microphone is accessed for the first time</string>
   ```

  When you create an archive of your app, the [privacy manifest settings required by Apple's App store](https://developer.apple.com/support/third-party-SDK-requirements) are added automatically with this version of the OpenTok React Native SDK.

4. Register the OpenTok OTPublisherViewNative and OTSubscriberViewNative classes. Do this by modifying the AppDelegate implementation.

   * If you app has an Objective-C++ AppDelegate file (AppDelegate.mm), add these classes to the list of packages in the NSMutableDictionary returned by the `thirdPartyFabricComponents()` function:

    <pre>
        #import "OTPublisherViewNativeComponentView.h"
        #import "OTSubscriberViewNativeComponentView.h"

        @implementation AppDelegate
            // ...
            - (NSDictionary<NSString *,Class<RCTComponentViewProtocol>> *)thirdPartyFabricComponents
        {
        NSMutableDictionary * dictionary = [super thirdPartyFabricComponents].mutableCopy;
        dictionary[@"OTPublisherViewNative"] = [OTPublisherViewNativeComponentView class];
        dictionary[@"OTSubscriberViewNative"] = [OTSubscriberViewNativeComponentView class];
        return dictionary;
        }
        
        @end
    </pre>

   * If your app uses a Swift AppDelegate file (AppDelegate.swift), you will need to have its implementation of the `RCTAppDelegate.application(_, didFinishLaunchingWithOptions)` method use a bridging header to call a method in an Objective-C++ file that calls the `[RCTComponentViewFactory registerComponentViewClass:]` method, passing in the `OTPublisherViewNativeComponentView` and `OTSubscriberViewNativeComponentView` classes.

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
     #import "OTPublisherViewNativeComponentView.h"
     #import "OTSubscriberViewNativeComponentView.h"
     
     @implementation FabricComponentRegistrar
     
     + (void)registerCustomComponents {
         RCTComponentViewFactory *factory = [RCTComponentViewFactory currentComponentViewFactory];
         [factory registerComponentViewClass:[OTPublisherViewNativeComponentView class]];
         [factory registerComponentViewClass:[OTSubscriberViewNativeComponentView class]];
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

5. If your app will use the `OTPublisher.setVideoTransformers()` or `OTPublisher.setAudioTransformers()` method, you need to include the following in your Podfile:

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

   - Run `react-native link opentok-react-native`

   This step is not necessary in React Native version 0.60 and later.

3. Run `bundle install`.

4. Make sure the following in your app's gradle `compileSdkVersion`, `buildToolsVersion`, `minSdkVersion`, and `targetSdkVersion` are greater than or equal to versions specified in the OpenTok React Native library.

5. The SDK automatically adds Android permissions it requires. You do not need to add these to your app manifest. However, certain permissions require you to prompt the user. See the [full list of required permissions](https://tokbox.com/developer/sdks/android/#permissions) in the Vonage Video API Android SDK documentation.

6. In the MainActivity.kt file for you app, register the OpenTok OpentokReactNativePackage, OTPublisherViewNativePackage, and OTSubscriberViewNativePackage packages. Do this by modifying the MainApplication file by adding these to the list of packages returned by the `getPackages()` function

    ```
    override fun getPackages(): List<ReactPackage> =
        PackageList(this).packages.apply {
            add(OTPublisherViewNativePackage())
            add(OTSubscriberViewNativePackage())
            add(OpentokReactNativePackage())
        }
        // ...
    ```

7. If your app will use the `OTPublisher.setVideoTransformers()` or `OTPublisher.setAudioTransformers()` method, you need to include the following in your app/build.gradle file:

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