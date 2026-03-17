# Vonage Video React Native SDK

<img src="https://assets.tokbox.com/img/vonage/Vonage_VideoAPI_black.svg" height="48px" alt="Tokbox is now known as Vonage" />

React Native library for using the [Vonage Video API](https://developer.vonage.com/en/video/overview). This library is officially supported by Vonage.

**📚 For complete documentation, installation instructions, API reference, and samples, visit:**  
**[https://developer.vonage.com/en/video/client-sdks/react-native/overview](https://developer.vonage.com/en/video/client-sdks/react-native/overview)**

---

## 📦 Monorepo Consolidation

This repository represents the **consolidated monorepo** for the Vonage Video React Native SDK. We merged previously separate branding-specific repositories (including [opentok-react-native](https://github.com/opentok/opentok-react-native)) into this single codebase to eliminate duplication and streamline maintenance.

This monorepo uses **brand-aware build configuration** to produce both OpenTok and Vonage branded artifacts from shared sources. Bug fixes and features are now automatically available to both brands from a single source of truth.

## Quick Start

### Installation

```bash
npm install @vonage/client-sdk-video-react-native@<VERSION>
# or
yarn add @vonage/client-sdk-video-react-native@<VERSION>
```

**Note:** Replace `<VERSION>` with the target version to use.

For complete installation instructions including iOS and Android setup, see the [official installation guide](https://developer.vonage.com/en/video/client-sdks/react-native/overview#installation).

### Basic Usage

```jsx
<OTSession applicationId="your-application-id" sessionId="your-session-id" token="your-session-token">
  <OTPublisher style={{ width: 100, height: 100 }}/>
  <OTSubscriber style={{ width: 100, height: 100 }} />
</OTSession>
```

---

## Important: React Native New Architecture Support

**Starting from version 2.31.1**, the Vonage Video React Native SDK is built with the [React Native new architecture](https://reactnative.dev/architecture/landing-page).

- ✅ **Supported:** React Native 0.76+ (new architecture)
- ❌ **Not supported:** Older React Native versions (legacy architecture)

Applications using older SDK versions will need to migrate to React Native's new architecture before upgrading. See the [installation guide](https://developer.vonage.com/en/video/client-sdks/react-native/overview#installation) for required package registration steps.

---

## Documentation & Resources

| Resource | Link |
|----------|------|
| **SDK Documentation** | [https://developer.vonage.com/en/video/client-sdks/react-native/overview](https://developer.vonage.com/en/video/client-sdks/react-native/overview) |
| **API Reference** | [https://vonage.github.io/video-docs/video-react-native-reference/latest](https://vonage.github.io/video-docs/video-react-native-reference/latest) |
| **Sample Applications** | [vonage-video-react-native-sdk-samples](https://github.com/Vonage/vonage-video-react-native-sdk-samples) |
| **Release Notes** | [https://developer.vonage.com/en/video/client-sdks/react-native/release-notes](https://developer.vonage.com/en/video/client-sdks/react-native/release-notes) |
| **Developer Guides** | [https://developer.vonage.com/en/video/overview](https://developer.vonage.com/en/video/overview) |

---

## Samples

To see this library in action, check out the [vonage-video-react-native-sdk-samples](https://github.com/Vonage/vonage-video-react-native-sdk-samples) repo, which includes:

- **Basic Video Chat** - Connect, publish, and subscribe to streams
- **Archiving** - Display recording indicators
- **Background Blur** - Apply video transformers
- **Multiparty** - Manage multiple participants
- **Signaling** - Send and receive text signals
- **Screen Sharing** - Publish screen-sharing streams

---

## Development and Contributing

Interested in contributing? We :heart: pull requests! See the [Contribution guidelines](CONTRIBUTING.md).

---

## Getting Help

We love to hear from you! If you have questions, comments, or find a bug in the project, let us know:

- **Open an issue** on this repository
- **Visit support:** [https://api.support.vonage.com/hc/en-us/](https://api.support.vonage.com/hc/en-us/)
- **Tweet at us:** [@VonageDev](https://twitter.com/VonageDev)
- **Join the community:** [Vonage Developer Community Slack](https://developer.nexmo.com/community/slack)

---

## License

This project is licensed under the Adobe-2 License. See the [LICENSE](LICENSE) file for details.
