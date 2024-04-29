# 2.27.4  (April 2024)

- [Update]: This version updates the Vonage Video iOS SDK version to 2.27.3. This version adds a [privacy manifest required by Apple's App store](https://developer.apple.com/support/third-party-SDK-requirements). Issue #737.

- [Update]: The installation instructions in the README file are updated, with new details on required Android permissions (such as `android.permission.BLUETOOTH`).

# 2.26.2  (April 2024)

- [Update]: This version updates the Vonage Video iOS SDK version to 2.26.3. This version adds a [privacy manifest required by Apple's App store](https://developer.apple.com/support/third-party-SDK-requirements). Issue #737.

# 2.25.5  (April 2024)
- [Update]: This version updates the Vonage Video iOS SDK version to 2.25.5. This version adds a [privacy manifest required by Apple's App store](https://developer.apple.com/support/third-party-SDK-requirements). Issue #737.

# 2.27.3  (March 2024)

- [Update]: This version updates the Vonage Video iOS SDK version to 2.27.2 and the Vonage Video Android SDK version to 2.27.1. See their release notes for details:

  * https://tokbox.com/developer/sdks/android/release-notes.html
  * https://tokbox.com/developer/sdks/ios/release-notes.html

- [Fix] Toggling between a screen and camera video source for publisher caused apps to crash in iOS. This version fixes the issue (issue #710).

# 2.27.2  (March 2024)

- [Fix]: On Android, a screen-sharing OTPublisher (one with the `videoSource` setting set to `"screen"`) failed if the app did not have camera access permission. This version fixes the issue, so that screen-sharing can proceed without camera access permission.

*Note:* In Android 6.0 (`API Level 23`) and higher, the OpenTok React Native SDK automatically adds the camera access permission. However, an app or user can disable it independently of the SDK.

- [Update]: Updates react-native and axios packages to fix vulnerable dependencies.

# 2.27.1  (March 2024)

- [Fix]: On Android, OTPublisher components failed with an error when either `PermissionsAndroid.PERMISSIONS.CAMERA` or `PermissionsAndroid.PERMISSIONS.RECORD_AUDIO` were not `true`. This version fixes that, by having audio-only or video-only publishers skip the `PermissionsAndroid.PERMISSIONS.CAMERA` or `PermissionsAndroid.PERMISSIONS.RECORD_AUDIO` check if the `videoTrack` or `audioTrack` property of the `properties` prop of the OTPublisher component is set to `false`. You can set these props to `false` based on these permissions:

```jsx
import { PermissionsAndroid } from 'react-native';
// ...

<OTPublisher
  properties={{
    videoTrack={{(Platform.OS === 'ios' || PermissionsAndroid.CAMERA)}}
  }}
/>
```

*Note:* In Android 6.0 (`API Level 23`) and higher, the OpenTok React Native SDK automatically adds these permissions. However, an app or user can disable them independently of the SDK.

- [Fix]: On Android, setting the `videoTrack` property of the `properties` prop of the OTPublisher component `false` resulted in the app to crash. This version fixes the issue (issue #652).

- [Fix]: Fixes some TypeScript definitions (issue #725).

# 2.27.0  (March 2024)

- [Update]: Update OpenTok Android SDK and OpenTok iOS SDK to version 2.27.0.

  This version adds support for the VP9 codec in relayed sessions. For more information, see the [video codecs](https://tokbox.com/developer/guides/codecs/) documentation.

  This version adds support for adaptive media routing. For more information, see the [adaptive media routing](https://tokbox.com/developer/guides/create-session/#adaptive-media-routing) documentation.

  For more details, see the release notes for the OpenTok [iOS](https://tokbox.com/developer/sdks/ios/release-notes.html) and [Android](https://tokbox.com/developer/sdks/android/release-notes.html) SDKs.

- [Update]: This version adds support for [end-to-end encryption](https://tokbox.com/developer/guides/end-to-end-encryption). The `OTSession` component includes a new `encryptionSecret` prop, which you can use to set and change the encryption secret used by the local client.

- [Update]: This version adds a new `OTPublisher audioFallback` option, which supports both subscriber and publisher audio fallback. The `audioFallback.subscriber` property replaces the `OTPublisher audioFallbackEnabled` option, which is deprecated.
The OTPublisher component has new callback functions for publisher audio fallback-related events: `videoDisabled()`, `videoEnabled()`, `videoDisableWarning()`, and `videoDisableWarningLifted()`. See the [audio fallback developer guide](https://tokbox.com/developer/guides/audio-fallback).

- [Update]: The `OTPublisher.setVideoTransformer()` method now supports the background image replacement transformer in Android (as well as iOS). And the custom radius option for the background blur filter is now supported in Android (as well as iOS).

- [Update]: The axios package is updated. This updates a vulnerable version of in the follow-redirects dependency.

- [Fix]: This version fixes some issues in the TypeScript definitions.

- [Fix]: This version fixes the following events, which were not being dispatched:

  * OTPublisher audioNetworkStats
  * OTPublisher videoNetworkStats
  * OTPublisher muteForced
  * OTSession muteForced

- [Fix]: This version fixes the `OTSession.forceMuteAll()` method in iOS.

# 2.26.1  (October 2023)

- [Update]: The new `OTPublisher.setVideoTransformers()` method lets you set (and clear)
  video transformers, such as a background blur for a publisher (issues #631 and #682).
  For more info, see the docs: [OTPublisher](/docs/OTPublisher.md).

- [Update]: Live Captions API enhancements (issue #643)

  * The new OTPublisher.publishCaptions option lets you enable and disable captions for a published stream  (if captions are enabled for the session). For more info, see the docs:[OTPublisher](/docs/OTPublisher.md).

  * The new OTSubscriber.subscribeToCaptions option lets you turn captions on and off for a subscriber (if captions are enabled for the session and the publisher is publishing captions). For more info, see the docs: [OTSubscriber](/docs/OTSubscriber.md).

  * The new OTSubscriber captionReceived event is dispatched when a subscriber receives a caption. For more info, see the docs: [OTSubscriber](/docs/OTSubscriber.md).

  * For more information, see the [Live Captions developer guide](https://tokbox.com/developer/guides/live-captions).

- [Fix]: Fixes an issue in which applications could not connect to a session when
  the `proxyUrl` option for OTSession was set. - issue #645

- [Fix]: Fixes an issue a stream is not destroyed immediately after unmounting an OTSession component or when the `OTSession.disconnect()` method is called. - issues #685 and #686

# 2.26.0  (October 2023)

- [Update]: Update OpenTok Android SDK and OpenTok iOS SDK to version 2.26.1.

  See the release notes for the OpenTok [ioS SDK](https://tokbox.com/developer/sdks/ios/release-notes.html)
  and the [Android SDK](https://tokbox.com/developer/sdks/android/release-notes.html).

  For Android, this version of the library requires a mininum Android API level of 23.

  There are changes to iOS 14 networking affecting relayed sessions — see the list of
  [known issues](https://tokbox.com/developer/sdks/ios/release-notes.html#known-issues)
  in the OpenTok iOS SDK release notes.

# 2.25.4 (October 2023)

- [Fix]: Fixes TypeScript definitions  - issue #690.

# 2.25.3 (September 2023)

- [Update]: Add API to implement functionality missing from the OpenTok Android and iOS SDKs:

  * `OTSession.getCapabilities()` method
  * `reportIssue()` methods and `rtcStatsReport` events added to OTPublisher and OTSubscriber
  * OTPublisher `scalableScreenshare` option (in the OTPublisher properties)
  * OTPublisher `audioNetworkStats` and `videoNetworkStats` events
  * `OTPublisher.getRtcStatsReport()` method and OTPublisher `rtcStatsReport` event
  * "1920x1080" option for OTPublisher `resolution` (for FHD video support)
  * OTSubscriber `audioVolume` property.
  * OT.getSupportedCodecs() method.
  * OT.forceMuteAll(), OT.forceMuteStream(), OT.disableForceMute() methods. OTPublisher
    `muteForce` event and OTSession `muteForced` event.

For more info, see the docs:

* [OTPublisher](/docs/OTPublisher.md)
* [OTSession](/docs/OTSession.md)
* [OTSubscriber](/docs/OTSubscriber.md)

- [Fix]: Fix android app crash due to permission missing.
- [Fix]: Fix OTSubscriber audioVolume and other properties not working -- issue #694

# 2.25.2 (July 5 2023)

- [Fix]: Fix crash on iOS when publishing a screen-sharing stream.

# 2.25.1  (June 27 2023)

- [Fix]: Fix camera lifecycle on Android. - issue #645

# 2.25.0  (May 17 2023)

- [Update]: Update OpenTok Android SDK and OpenTok iOS SDK to version 2.25.1.

  Note that with this version, we are pinning the major and minor release versions
  (2.25) to match the corresponding versions in the OpenTok Android and iOS SDKs.

  For iOS, note that this version supports iOS 13+, removes support for FAT binaries
  and drops 32-bit support. The OpenTok iOS SDK is now available as the OTXCFramework
  Pod file. (The OpenTok pod file was for FAT binaries.)

  See the release notes for the OpenTok [ioS SDK](https://tokbox.com/developer/sdks/ios/release-notes.html)
  and the [Android SDK](https://tokbox.com/developer/sdks/android/release-notes.html).

- [Fix]: Fixes an issue in which applications could not connect to a session when
  the `proxyUrl` option for OTSession was set. - issue #645

# 0.21.4 (April 12 2023)

- [Update]: Revert OpenTok iOS SDK back 2.23.1. There are issues with
  linked libraries in the OpenTok iOS SDK v2.24.0+ that cause
  issues when used in React Native. We are working on a bug fix.

# 0.21.3 (March 2023)

- [Update]: iOS SDK to 2.24.2 and Android to 2.24.2 - issue #629

# 0.21.2 (February 14, 2023)

- [Update]: iOS SDK to 2.23.1 and Android to 2.23.1
- [Fix]: Fix video freeze issue in Android 13 simulator (API level 33) - issue #628

# 0.21.1 (Oct 14, 2022)

- [Update]: iOS SDK to 2.23.1 and Android to 2.23.1
- [Update]: min target for iOS is now 12.0

# 0.21.0 (June 14, 2022)

- [Update]: Add DTX Option for Publisher
- [Update]: Android Native SDK to 2.22.3 and iOS to 2.22.3

# 0.20.3 (May 18, 2022)

- [Fix]: Updates from DependatBot

# 0.20.2 (May 16, 2022)

- [Update]: Readme file update with Bintray instructions
- [Update]: Android Native SDK to 2.21.5 and iOS to 2.21.3
- [Fix]: Typescrit types fixed audioLevel

# 0.20.1 (Jan 28, 2022)
- [Update]: Add Content Hint API on the OTPublisher object
- [Update]: Add timestamp property on the audioNetworkStats and videoNetworkStats
- [Fix]: Bump `opentok-react-native` version to 

# 0.20.0 (Jan 26, 2022)
- [Update]: update SDKs iOS to 2.21.3 and Android to 2.21.4 

# 0.19.0 (Oct 11, 2021)
- [Update]: update SDKs Android to 2.20.2
- [Update]: added IceConfig options in the Session Options object
- [Fix]: added missing typings in @types/index.d.ts
- [Fix]: fix crash in OTSubscriberLayout [#525](https://github.com/opentok/opentok-react-native/pull/525)

# 0.18.0 (Jun 24, 2021)
- [Update]: update SDKs iOS to 2.20.0 and Android to 2.20.1
- [Fix]: fix crash in OTPublisherLayout when sessionId is null. Fix: https://github.com/opentok/opentok-react-native/issues/462#issuecomment-752171962
- [Fix]: Downgrade uuidv4 module to `3.4.0` due to [UUID#375](https://github.com/uuidjs/uuid/issues/375)
- [Fix]: OTCustomAudioDrive added file in project.pbxproj
- [Fix]: Update Github Actions 

# 0.17.2 (May 27, 2021)
- **[Fix]**: Fixed incorrect audio bitrate sanitization [#473](https://github.com/opentok/opentok-react-native/pull/473)
- **[Fix]**: Fix audio crash on teardown [#495](https://github.com/opentok/opentok-react-native/pull/495)

# 0.17.1 (May 25, 2021)

- **[Fix]**: Fixed @opentok/types (merged from [PR505](https://github.com/opentok/opentok-react-native/pull/505))
- **[Fix]**: Fixed double listeners [#271](https://github.com/opentok/opentok-react-native/issues/271) (merged from [PR307](https://github.com/opentok/opentok-react-native/pull/307))


# 0.17.0 (Apr 29, 2021)

- **[Feature]**: Updated to react-native 0.64.0
- **[Fix]**: Updated npm dependencies
- **[Fix]**: Fixed react-native 0.64.0 `nativeEvents.listeners()` crash [PR493](https://github.com/opentok/opentok-react-native/pull/493)

# 0.16.0 (Apr 19, 2021)

- **[Feature]**: Added support for `stereo` output on `iOS` and `Android` using `CustomAudioDevice`

# 0.15.0 (Jan 26, 2021)

- **[Feature]**: OTSubscriber: added [preferredResolution](https://tokbox.com/developer/sdks/js/reference/Subscriber.html#setPreferredResolution) and [preferredFrameRate](https://tokbox.com/developer/sdks/js/reference/Subscriber.html#setPreferredFrameRate) properties.
- **[Fix]**: Fixed android app crash with API level 29 (merged from [PR456](https://github.com/opentok/opentok-react-native/pull/456)). Adheres to: [#455](https://github.com/opentok/opentok-react-native/issues/455)
- iOS SDK updated to `2.18.1`
- Android SDK updated to `2.18.1`
- Added typescript support 

# 0.14.0 (May 22, 2020)

- **[Feature]**: Update of iOS SDK to `2.17.0` and Android SDK to `2.17.1`
- OTSessionManager.java#248 mSubscriber.destroy() removed as from 2.17.x, resources will be automatically released by the garbage collector.

# 0.13.0 (Mar 23, 2020)

- **[Feature]**: Add Session Options support, both [iOS](https://tokbox.com/developer/sdks/ios/reference/Classes/OTSessionSettings.html) and [Android](https://tokbox.com/developer/sdks/android/reference/). Note: iceConfig option is not currently supported
- **[Feature]**: Update of iOS SDK to `2.16.5` and Android SDK to `2.16.5`


# 0.12.2 (Dec 4, 2019)

-   **[Fix]**: Prevent to unpublish on disconnected sessions (merged from [PR356](https://github.com/opentok/opentok-react-native/pull/356)). Adheres to: [#337](https://github.com/opentok/opentok-react-native/issues/337)
-   **[Feature]**: Add podspec for autolinking support in RN 0.6x (merged from [PR358](https://github.com/opentok/opentok-react-native/pull/358)). Adheres to: [#332](https://github.com/opentok/opentok-react-native/issues/332)
-   Android SDK updated to `2.16.3`

# 0.12.1 (Aug 30, 2019)

-   **[Fix]**: Fix an error when updating streamId for subscriber component (merged from [PR326](https://github.com/opentok/opentok-react-native/pull/326)). Adheres to: [#315](https://github.com/opentok/opentok-react-native/issues/315), [#324](https://github.com/opentok/opentok-react-native/issues/324)
-   **[Fix]**: Use Context API for passing props down the component tree (merged from [PR333](https://github.com/opentok/opentok-react-native/pull/333)). Adheres to: [#329](https://github.com/opentok/opentok-react-native/issues/329), [#335](https://github.com/opentok/opentok-react-native/issues/335)
-   **[Fix]**: Fix `Attempted to register RCTBridgeModule class OTSessionManager` issue after opening/reloading app (merged from [PR336](https://github.com/opentok/opentok-react-native/pull/336)).
-   **[Fix]**: Fix reload in iOS (merged from [PR339](https://github.com/opentok/opentok-react-native/pull/339)).
-   **[Fix]**: Fix security vulnerabilities on dependencies (merged from [PR339](https://github.com/opentok/opentok-react-native/pull/340)).


# 0.12.0 (Aug 5, 2019)

-   **[Feature]**: Add Multi-session support (merged from [PR311](https://github.com/opentok/opentok-react-native/pull/311)). Adheres to: [#218](https://github.com/opentok/opentok-react-native/issues/218), [#271](https://github.com/opentok/opentok-react-native/issues/271)


# 0.11.2 (July 2, 2019)

-   **[Feature]**: Enable `OTSubscriber` children custom render (merged from [PR306](https://github.com/opentok/opentok-react-native/pull/306)). Adheres to: [#289](https://github.com/opentok/opentok-react-native/issues/289), [#174](https://github.com/opentok/opentok-react-native/issues/174)
-  iOS SDK updated to `2.16.1`
-  Android SDK updated to `2.16.1`
  
# 0.x.x (todo)
