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

