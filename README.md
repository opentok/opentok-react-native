:warning: **This repository has been deprecated in favour of the [Vonage Video React Native SDK](https://github.com/Vonage/vonage-video-react-native-sdk) repository** :warning:

> **Why this change?** We've consolidated our Vonage and OpenTok branded React Native SDKs into a single monorepo to eliminate code duplication. The [Vonage Video React Native SDK](https://github.com/Vonage/vonage-video-react-native-sdk) repository uses brand-aware build configuration to produce both Vonage and OpenTok artifacts from shared sources.

# OpenTok React Native SDK

<img src="https://assets.tokbox.com/img/vonage/Vonage_VideoAPI_black.svg" height="48px" alt="Tokbox is now known as Vonage" />

React Native library for using [OpenTok](https://tokbox.com/developer/) / Vonage Video API. This library is officially supported by Vonage.

**📚 For complete documentation, installation instructions, API reference, and samples, visit:**  
**[https://tokbox.com/developer/sdks/react-native/](https://tokbox.com/developer/sdks/react-native/)**

---

## Quick Start

### Installation

```bash
npm install opentok-react-native@<VERSION>
# or
yarn add opentok-react-native@<VERSION>
```

**Note:** Replace `<VERSION>` with the target version to use.

For complete installation instructions including iOS and Android setup, see the [official installation guide](https://tokbox.com/developer/sdks/react-native/#installation).

### Basic Usage

```jsx
<OTSession apiKey="your-api-key" sessionId="your-session-id" token="your-session-token">
  <OTPublisher style={{ width: 100, height: 100 }}/>
  <OTSubscriber style={{ width: 100, height: 100 }} />
</OTSession>
```

---

## Important: React Native New Architecture Support

**Starting from version 2.31.1**, the OpenTok React Native SDK is built with the [React Native new architecture](https://reactnative.dev/architecture/landing-page).

- ✅ **Supported:** React Native 0.76+ (new architecture)
- ❌ **Not supported:** Older React Native versions (legacy architecture)

Applications using older SDK versions will need to migrate to React Native's new architecture before upgrading. See the [installation guide](https://tokbox.com/developer/sdks/react-native/#installation) for required package registration steps.

---

## Documentation & Resources

| Resource | Link |
|----------|------|
| **SDK Documentation** | [https://tokbox.com/developer/sdks/react-native/](https://tokbox.com/developer/sdks/react-native/) |
| **API Reference** | [https://tokbox.com/developer/sdks/react-native/reference](https://tokbox.com/developer/sdks/react-native/reference) |
| **Sample Applications** | [opentok-react-native-samples](https://github.com/opentok/opentok-react-native-samples) |
| **Release Notes** | [https://tokbox.com/developer/sdks/react-native/release-notes](https://tokbox.com/developer/sdks/react-native/release-notes) |
| **Developer Guides** | [https://tokbox.com/developer/guides](https://tokbox.com/developer/guides) |

---

## Samples

To see this library in action, check out the [opentok-react-native-samples](https://github.com/opentok/opentok-react-native-samples) repo, which includes:

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
- **Visit support:** [https://support.tokbox.com/](https://support.tokbox.com/)
- **Tweet at us:** [@VonageDev](https://twitter.com/VonageDev)
- **Join the community:** [Vonage Developer Community Slack](https://developer.nexmo.com/community/slack)

---

## License

This project is licensed under the Adobe-2 License. See the [LICENSE](LICENSE) file for details.
