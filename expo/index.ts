import {
  type ConfigPlugin,
  withAndroidManifest,
  withInfoPlist,
  AndroidConfig,
  withPlugins,
} from '@expo/config-plugins';

export interface VonagePluginiOSProps {
  /**
   * iOS camera permission message
   * @default 'Allow $(PRODUCT_NAME) to access your camera for video calls'
   */
  cameraPermission?: string;
  /**
   * iOS microphone permission message
   * @default 'Allow $(PRODUCT_NAME) to access your microphone for audio calls'
   */
  microphonePermission?: string;
}

/**
 * Add iOS Info.plist entries for camera and microphone permissions
 */
const withIosPermissions: ConfigPlugin<VonagePluginiOSProps> = (
  config,
  props
) => {
  const {
    cameraPermission = 'Allow $(PRODUCT_NAME) to access your camera for video calls',
    microphonePermission = 'Allow $(PRODUCT_NAME) to access your microphone for audio calls',
  } = props;

  return withInfoPlist(config, (config) => {
    config.modResults.NSCameraUsageDescription = cameraPermission;
    config.modResults.NSMicrophoneUsageDescription = microphonePermission;
    return config;
  });
};

/**
 * Add Android permissions to AndroidManifest.xml
 */
const withAndroidPermissions: ConfigPlugin = (config) => {
  return withAndroidManifest(config, (config) => {
    const permissions = [
      'android.permission.BLUETOOTH',
      'android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      'android.permission.BLUETOOTH_CONNECT',
      'android.permission.BROADCAST_STICKY',
      'android.permission.CAMERA',
      'android.permission.INTERNET',
      'android.permission.MODIFY_AUDIO_SETTINGS',
      'android.permission.READ_PHONE_STATE',
      'android.permission.RECORD_AUDIO',
      'android.permission.ACCESS_NETWORK_STATE',
    ];

    permissions.forEach((permission) => {
      AndroidConfig.Permissions.addPermission(config.modResults, permission);
    });

    // Add hardware feature for camera (non-required)
    if (!config.modResults.manifest['uses-feature']) {
      config.modResults.manifest['uses-feature'] = [];
    }

    const cameraFeatureExists = config.modResults.manifest['uses-feature'].some(
      (feature: any) => feature.$['android:name'] === 'android.hardware.camera'
    );

    if (!cameraFeatureExists) {
      config.modResults.manifest['uses-feature'].push({
        $: {
          'android:name': 'android.hardware.camera',
          'android:required': 'false',
        },
      });
    }

    return config;
  });
};

/**
 * Main Expo Config Plugin for @vonage/client-sdk-video-react-native
 * Automatically configures native permissions and dependencies
 */
const withVonage: ConfigPlugin<VonagePluginiOSProps> = (
  config,
  props = {}
) => {
  return withPlugins(config, [
    [withIosPermissions, props],
    withAndroidPermissions,
  ]);
};

export default withVonage;
