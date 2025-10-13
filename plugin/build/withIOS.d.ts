import type { ConfigPlugin } from "@expo/config-plugins";
import type { OpentokPluginProps } from "./types";
/**
 * Adds required usage descriptions to Info.plist for OpenTok video calls.
 *
 * Required keys:
 * - NSCameraUsageDescription: Explains why camera access is needed
 * - NSMicrophoneUsageDescription: Explains why microphone access is needed
 *
 * These are required by Apple's App Store review process.
 */
export declare const withOpentokIOS: ConfigPlugin<OpentokPluginProps>;
//# sourceMappingURL=withIOS.d.ts.map