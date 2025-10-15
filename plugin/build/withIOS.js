"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.withOpentokIOS = void 0;
const config_plugins_1 = require("@expo/config-plugins");
const CAMERA_USAGE = "Allow $(PRODUCT_NAME) to access your camera for video calls.";
const MICROPHONE_USAGE = "Allow $(PRODUCT_NAME) to access your microphone for audio calls.";
/**
 * Adds required usage descriptions to Info.plist for OpenTok video calls.
 *
 * Required keys:
 * - NSCameraUsageDescription: Explains why camera access is needed
 * - NSMicrophoneUsageDescription: Explains why microphone access is needed
 *
 * These are required by Apple's App Store review process.
 */
const withOpentokIOS = (config, props = {}) => {
    return (0, config_plugins_1.withInfoPlist)(config, (config) => {
        const infoPlist = config.modResults;
        // Set camera usage description
        // Only set if not already set or if custom message provided
        if (props.cameraPermission || !infoPlist.NSCameraUsageDescription) {
            infoPlist.NSCameraUsageDescription =
                props.cameraPermission || CAMERA_USAGE;
        }
        // Set microphone usage description
        // Only set if not already set or if custom message provided
        if (props.microphonePermission || !infoPlist.NSMicrophoneUsageDescription) {
            infoPlist.NSMicrophoneUsageDescription =
                props.microphonePermission || MICROPHONE_USAGE;
        }
        return config;
    });
};
exports.withOpentokIOS = withOpentokIOS;
//# sourceMappingURL=withIOS.js.map