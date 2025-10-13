/**
 * Configuration options for the OpenTok React Native Expo config plugin.
 */
export interface OpentokPluginProps {
  /**
   * Custom message to display when requesting camera permission on iOS.
   * This message will be shown in the NSCameraUsageDescription field.
   * @default "Allow $(PRODUCT_NAME) to access your camera for video calls."
   */
  cameraPermission?: string;

  /**
   * Custom message to display when requesting microphone permission on iOS.
   * This message will be shown in the NSMicrophoneUsageDescription field.
   * @default "Allow $(PRODUCT_NAME) to access your microphone for audio calls."
   */
  microphonePermission?: string;

  /**
   * Whether to include Bluetooth permissions (Android only).
   * Required if using Bluetooth audio devices.
   * @default false
   */
  enableBluetoothPermissions?: boolean;
}
