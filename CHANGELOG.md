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