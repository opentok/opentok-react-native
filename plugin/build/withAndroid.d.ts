import type { ConfigPlugin } from "@expo/config-plugins";
import type { OpentokPluginProps } from "./types";
/**
 * Adds required permissions to AndroidManifest.xml for OpenTok video calls.
 *
 * Required permissions:
 * - CAMERA: Access camera for video
 * - RECORD_AUDIO: Access microphone for audio
 * - INTERNET: Required for WebRTC connections
 * - MODIFY_AUDIO_SETTINGS: Required for audio configuration
 *
 * Optional permissions (if enableBluetoothPermissions is true):
 * - BLUETOOTH: Use Bluetooth audio devices
 * - BLUETOOTH_CONNECT: Connect to Bluetooth devices (Android 12+)
 */
export declare const withOpentokAndroid: ConfigPlugin<OpentokPluginProps>;
//# sourceMappingURL=withAndroid.d.ts.map