import type { ConfigPlugin } from "@expo/config-plugins";
import { createRunOncePlugin } from "@expo/config-plugins";
import { withOpentokAndroid } from "./withAndroid";
import { withOpentokIOS } from "./withIOS";
import type { OpentokPluginProps } from "./types";

/**
 * Expo config plugin for OpenTok React Native.
 *
 * This plugin automatically configures the necessary permissions and usage descriptions
 * required for video calling functionality using the OpenTok/Vonage Video API.
 *
 * ## What it does:
 *
 * **iOS:**
 * - Adds NSCameraUsageDescription to Info.plist
 * - Adds NSMicrophoneUsageDescription to Info.plist
 *
 * **Android:**
 * - Adds CAMERA permission to AndroidManifest.xml
 * - Adds RECORD_AUDIO permission to AndroidManifest.xml
 * - Adds INTERNET permission to AndroidManifest.xml
 * - Adds MODIFY_AUDIO_SETTINGS permission to AndroidManifest.xml
 * - Adds ACCESS_NETWORK_STATE permission to AndroidManifest.xml
 * - Optionally adds Bluetooth permissions
 *
 * ## Usage:
 *
 * Add to your app.json or app.config.js:
 *
 * ```json
 * {
 *   "expo": {
 *     "plugins": [
 *       [
 *         "opentok-react-native",
 *         {
 *           "cameraPermission": "Allow $(PRODUCT_NAME) to access your camera for video calls.",
 *           "microphonePermission": "Allow $(PRODUCT_NAME) to access your microphone for audio calls.",
 *           "enableBluetoothPermissions": false
 *         }
 *       ]
 *     ]
 *   }
 * }
 * ```
 *
 * ## Configuration Options:
 *
 * @param config - The Expo config object
 * @param props - Configuration options for the plugin
 * @param props.cameraPermission - Custom message for camera permission (iOS only)
 * @param props.microphonePermission - Custom message for microphone permission (iOS only)
 * @param props.enableBluetoothPermissions - Whether to add Bluetooth permissions (Android only)
 *
 * @returns Modified config object
 *
 * @example
 * // In app.config.js
 * export default {
 *   plugins: [
 *     [
 *       "opentok-react-native",
 *       {
 *         cameraPermission: "We need camera access for video calls",
 *         microphonePermission: "We need microphone access for audio"
 *       }
 *     ]
 *   ]
 * }
 */
const withOpentokReactNative: ConfigPlugin<OpentokPluginProps> = (
  config,
  props = {}
) => {
  // Apply iOS configuration
  config = withOpentokIOS(config, props);

  // Apply Android configuration
  config = withOpentokAndroid(config, props);

  return config;
};

// Export the plugin wrapped with createRunOncePlugin to prevent multiple executions
const pkg = {
  name: "opentok-react-native",
  version: "2.31.0",
};

export default createRunOncePlugin(withOpentokReactNative, pkg.name, pkg.version);

// Also export the raw plugin for testing purposes
export { withOpentokReactNative };

// Export types
export type { OpentokPluginProps };
