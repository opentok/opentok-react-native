"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.withOpentokAndroid = void 0;
const config_plugins_1 = require("@expo/config-plugins");
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
const withOpentokAndroid = (config, props = {}) => {
    return (0, config_plugins_1.withAndroidManifest)(config, async (config) => {
        const manifest = config.modResults;
        // Ensure uses-permission array exists
        if (!manifest.manifest["uses-permission"]) {
            manifest.manifest["uses-permission"] = [];
        }
        const permissions = manifest.manifest["uses-permission"];
        // Required permissions for OpenTok video calls
        const requiredPermissions = [
            "android.permission.CAMERA",
            "android.permission.RECORD_AUDIO",
            "android.permission.INTERNET",
            "android.permission.MODIFY_AUDIO_SETTINGS",
            "android.permission.ACCESS_NETWORK_STATE",
        ];
        // Add Bluetooth permissions if requested
        if (props.enableBluetoothPermissions) {
            requiredPermissions.push("android.permission.BLUETOOTH", "android.permission.BLUETOOTH_CONNECT");
        }
        // Add each permission if it doesn't already exist
        for (const permission of requiredPermissions) {
            const permissionExists = permissions.some((p) => { var _a; return ((_a = p.$) === null || _a === void 0 ? void 0 : _a["android:name"]) === permission; });
            if (!permissionExists) {
                permissions.push({
                    $: {
                        "android:name": permission,
                    },
                });
            }
        }
        return config;
    });
};
exports.withOpentokAndroid = withOpentokAndroid;
//# sourceMappingURL=withAndroid.js.map