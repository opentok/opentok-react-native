import type { ConfigPlugin } from "@expo/config-plugins";
import { withInfoPlist } from "@expo/config-plugins";
import type { OpentokPluginProps } from "./types";

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
export const withOpentokIOS: ConfigPlugin<OpentokPluginProps> = (
  config,
  props = {}
) => {
  return withInfoPlist(config, (config) => {
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
