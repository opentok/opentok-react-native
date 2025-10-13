# Expo Setup Guide for OpenTok React Native

This guide provides detailed instructions for using the OpenTok React Native SDK with Expo SDK 54+.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [New Architecture Support](#new-architecture-support)
- [EAS Build](#eas-build)
- [Troubleshooting](#troubleshooting)
- [Migration from React Native CLI](#migration-from-react-native-cli)

## Prerequisites

- **Expo SDK 54+** (includes React Native 0.81+)
- **Node.js 18+**
- **Expo CLI**: `npm install -g expo-cli`
- **EAS CLI** (optional, for cloud builds): `npm install -g eas-cli`

## Quick Start

### 1. Create a New Expo Project (or use an existing one)

```bash
npx create-expo-app my-video-app
cd my-video-app
```

### 2. Install OpenTok React Native

```bash
npx expo install opentok-react-native
```

### 3. Configure the Config Plugin

Add the plugin to your `app.json`:

```json
{
  "expo": {
    "name": "My Video App",
    "slug": "my-video-app",
    "plugins": [
      [
        "opentok-react-native",
        {
          "cameraPermission": "We need camera access for video calls",
          "microphonePermission": "We need microphone access for audio calls"
        }
      ]
    ]
  }
}
```

Or in `app.config.js` for dynamic configuration:

```javascript
export default {
  expo: {
    name: "My Video App",
    slug: "my-video-app",
    plugins: [
      [
        "opentok-react-native",
        {
          cameraPermission: "We need camera access for video calls",
          microphonePermission: "We need microphone access for audio calls",
          enableBluetoothPermissions: false, // Optional: Android only
        },
      ],
    ],
  },
};
```

### 4. Generate Native Projects

```bash
npx expo prebuild --clean
```

This command:
- Generates iOS and Android native projects
- Applies the config plugin
- Adds all required permissions
- Registers Fabric components

### 5. Run Your App

```bash
# iOS
npx expo run:ios

# Android
npx expo run:android
```

## Configuration

### Config Plugin Options

| Option | Type | Platform | Description | Default |
|--------|------|----------|-------------|---------|
| `cameraPermission` | `string` | iOS | Custom message for camera permission prompt | `"Allow $(PRODUCT_NAME) to access your camera for video calls."` |
| `microphonePermission` | `string` | iOS | Custom message for microphone permission prompt | `"Allow $(PRODUCT_NAME) to access your microphone for audio calls."` |
| `enableBluetoothPermissions` | `boolean` | Android | Add Bluetooth permissions for audio devices | `false` |

### Example: Minimal Configuration

```json
{
  "expo": {
    "plugins": ["opentok-react-native"]
  }
}
```

Uses default permission messages.

### Example: Custom Permission Messages

```json
{
  "expo": {
    "plugins": [
      [
        "opentok-react-native",
        {
          "cameraPermission": "$(PRODUCT_NAME) needs camera access to let you video chat with other users.",
          "microphonePermission": "$(PRODUCT_NAME) needs microphone access to let you talk to other users."
        }
      ]
    ]
  }
}
```

### Example: Enable Bluetooth Support (Android)

```json
{
  "expo": {
    "plugins": [
      [
        "opentok-react-native",
        {
          "enableBluetoothPermissions": true
        }
      ]
    ]
  }
}
```

## New Architecture Support

OpenTok React Native SDK **requires** React Native's new architecture. Expo SDK 54 includes React Native 0.81, which has the new architecture enabled by default.

### What This Means for You

- ✅ **Faster rendering** with Fabric
- ✅ **Better performance** with TurboModules
- ✅ **Type safety** between JavaScript and native code
- ✅ **No manual configuration needed** - the config plugin handles everything

### Component Registration

The config plugin automatically handles Fabric component registration. You don't need to modify `AppDelegate` or `MainActivity` files manually.

**What gets registered automatically:**
- `OTRNPublisher` - Video publisher component
- `OTRNSubscriber` - Video subscriber component
- `OpentokReactNative` - TurboModule for session management

## EAS Build

OpenTok React Native works seamlessly with EAS Build.

### 1. Configure EAS

```bash
eas build:configure
```

### 2. Create `eas.json`

```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": true
      }
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "autoIncrement": true
    }
  }
}
```

### 3. Run Builds

```bash
# Development build for testing
eas build --profile development --platform all

# Preview build for internal testing
eas build --profile preview --platform all

# Production build for app stores
eas build --profile production --platform all
```

### 4. Install Development Build

After the development build completes:

```bash
# iOS Simulator
eas build:run -p ios --latest

# Android Emulator
eas build:run -p android --latest
```

Then start your development server:

```bash
npx expo start --dev-client
```

## Troubleshooting

### Issue: "Module not found: opentok-react-native"

**Solution:**
```bash
# Clear cache and reinstall
rm -rf node_modules
npm install
# or
yarn install
```

### Issue: "Native module cannot be found"

**Solution:**
```bash
# Regenerate native projects
npx expo prebuild --clean
```

### Issue: Permissions not appearing in Info.plist or AndroidManifest.xml

**Solution:**

1. Check your `app.json` syntax:
   ```bash
   npx expo config --type public
   ```

2. Ensure the plugin is listed:
   ```json
   {
     "expo": {
       "plugins": ["opentok-react-native"]
     }
   }
   ```

3. Run prebuild with clean flag:
   ```bash
   npx expo prebuild --clean
   ```

4. Verify generated files:
   - iOS: `ios/[YourApp]/Info.plist`
   - Android: `android/app/src/main/AndroidManifest.xml`

### Issue: "Component OTRNPublisher not found"

**Solution:**

This means Fabric components aren't registered. Run:

```bash
npx expo prebuild --clean
```

The config plugin automatically handles component registration in:
- iOS: `AppDelegate`
- Android: `MainApplication`

### Issue: Build fails with "Duplicate symbols"

**Solution:**

Clean your build directories:

```bash
# iOS
cd ios
rm -rf build
pod deintegrate
pod install
cd ..

# Android
cd android
./gradlew clean
cd ..

# Then rebuild
npx expo run:ios
# or
npx expo run:android
```

### Issue: Camera/Microphone permission crashes app

**Solution:**

1. Ensure you've added the config plugin to `app.json`
2. Run `npx expo prebuild --clean`
3. Check that permission strings exist in native files
4. For iOS, check `Info.plist` for:
   - `NSCameraUsageDescription`
   - `NSMicrophoneUsageDescription`

### Debug Mode

Enable debug output:

```bash
EXPO_DEBUG=1 npx expo prebuild --clean
```

This shows all plugin modifications being applied.

## Migration from React Native CLI

### 1. Install Expo

```bash
npx install-expo-modules
```

### 2. Update package.json

Remove React Native CLI scripts and add Expo scripts:

```json
{
  "scripts": {
    "start": "expo start",
    "android": "expo run:android",
    "ios": "expo run:ios"
  }
}
```

### 3. Create app.json

```json
{
  "expo": {
    "name": "YourApp",
    "slug": "your-app",
    "plugins": [
      [
        "opentok-react-native",
        {
          "cameraPermission": "Your camera permission message",
          "microphonePermission": "Your microphone permission message"
        }
      ]
    ]
  }
}
```

### 4. Remove Manual Configuration

You can now remove manual configuration from:

**iOS:**
- Manual `Info.plist` entries (config plugin adds these)
- Manual component registration in `AppDelegate`

**Android:**
- Manual `AndroidManifest.xml` permissions (config plugin adds these)
- Manual package registration in `MainApplication`

### 5. Run Prebuild

```bash
npx expo prebuild
```

## Example App

### Basic Video Call Component

```typescript
import React, { useState } from "react";
import { View, Button, StyleSheet } from "react-native";
import { OTSession, OTPublisher, OTSubscriber } from "opentok-react-native";

export default function VideoCall() {
  const [isConnected, setIsConnected] = useState(false);

  const API_KEY = "YOUR_API_KEY";
  const SESSION_ID = "YOUR_SESSION_ID";
  const TOKEN = "YOUR_TOKEN";

  return (
    <View style={styles.container}>
      <OTSession
        apiKey={API_KEY}
        sessionId={SESSION_ID}
        token={TOKEN}
        eventHandlers={{
          sessionConnected: () => {
            console.log("Session connected");
            setIsConnected(true);
          },
          sessionDisconnected: () => {
            console.log("Session disconnected");
            setIsConnected(false);
          },
          error: (error) => {
            console.error("Session error:", error);
          },
        }}
      >
        {isConnected && (
          <>
            <OTPublisher style={styles.publisher} />
            <OTSubscriber style={styles.subscriber} />
          </>
        )}
      </OTSession>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  publisher: {
    width: 100,
    height: 100,
    position: "absolute",
    top: 50,
    right: 10,
    zIndex: 2,
  },
  subscriber: {
    flex: 1,
  },
});
```

## Additional Resources

- [OpenTok React Native API Documentation](https://tokbox.com/developer/sdks/react-native/reference)
- [Expo Config Plugins Documentation](https://docs.expo.dev/config-plugins/introduction/)
- [React Native New Architecture Guide](https://reactnative.dev/architecture/landing-page)
- [OpenTok Sample Apps](https://github.com/opentok/opentok-react-native-samples)

## Getting Help

If you encounter issues:

1. Check this troubleshooting guide
2. Search [existing GitHub issues](https://github.com/opentok/opentok-react-native/issues)
3. Create a new issue with:
   - Expo SDK version
   - React Native version
   - Error message and stack trace
   - Steps to reproduce

## License

MIT License - see [LICENSE](./LICENSE) file for details.
