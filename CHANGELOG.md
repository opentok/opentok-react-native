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

This is the first client-sdk-video-react-native version of the React Native
SDK for the Vonage Video API. There is also an opentok-react-native package,
a version for OpenTok developers. See the change log for that package
for informations on previous versions:
https://github.com/opentok/opentok-react-native/blob/develop/CHANGELOG.md. 

- [Update]: Update Voange Video Android SDK and Voange Video iOS SDK to version 2.27.0.

  This version adds support for the VP9 codec in relayed sessions. For more information, see the [video codecs](https://developer.vonage.com/en/video/guides/codecs) documentation.

  This version adds support for adaptive media routing. For more information, see the information on adaptive media routing in this documentation: https://developer.vonage.com/en/video/guides/create-session.

  For more details, see the release notes for the Voange Video [iOS](https://developer.vonage.com/en/video/client-sdks/ios/release-notes) and [Android](https://developer.vonage.com/en/video/client-sdks/android/release-notes) SDKs.

- [Update]: This version adds support for [end-to-end encryption](https://developer.vonage.com/en/video/guides/end-to-end-encryption). The `OTSession` component includes a new `encryptionSecret` prop, which you can use to set and change the encryption secret used by the local client.

- [Update]: This version adds a new `OTPublisher audioFallback` option, which supports both subscriber and publisher audio fallback. The `audioFallback.subscriber` property replaces the `OTPublisher audioFallbackEnabled` option, which is deprecated.
The OTPublisher component has new callback functions for publisher audio fallback-related events: `videoDisabled()`, `videoEnabled()`, `videoDisableWarning()`, and `videoDisableWarningLifted()`.

- [Update]: The `OTPublisher.setVideoTransformer()` method now supports the background image replacement transformer in Android (as well as iOS). And the custom radius option for the background blur filter is now supported in Android (as well as iOS).

- [Update]: The axios package is updated. This updates a vulnerable version of in the follow-redirects dependency.

- [Fix]: This version fixes some issues in the TypeScript definitions.

- [Fix]: This version fixes the following events, which were not being dispatched:

  * OTPublisher audioNetworkStats
  * OTPublisher videoNetworkStats
  * OTPublisher muteForced
  * OTSession muteForced

- [Fix]: This version fixes the `OTSession.forceMuteAll()` method in iOS.

