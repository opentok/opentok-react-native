const iosBuildCmd =
  process.env.DETOX_BUILD_IOS ||
  "node -e \"console.error('Set DETOX_BUILD_IOS to your iOS sample app build command'); process.exit(1)\"";

const androidBuildCmd =
  process.env.DETOX_BUILD_ANDROID ||
  "node -e \"console.error('Set DETOX_BUILD_ANDROID to your Android sample app build command'); process.exit(1)\"";

const iosBinaryPath = process.env.DETOX_IOS_BINARY_PATH || '';
const androidBinaryPath = process.env.DETOX_ANDROID_BINARY_PATH || '';

afterEnvCheck();

function afterEnvCheck() {
  if (!process.env.DETOX_IOS_BINARY_PATH) {
    // eslint-disable-next-line no-console
    console.warn('[Detox] DETOX_IOS_BINARY_PATH is not set. iOS e2e build/test will fail until configured.');
  }
  if (!process.env.DETOX_ANDROID_BINARY_PATH) {
    // eslint-disable-next-line no-console
    console.warn('[Detox] DETOX_ANDROID_BINARY_PATH is not set. Android e2e build/test will fail until configured.');
  }
}

/** @type {Detox.DetoxConfig} */
module.exports = {
  testRunner: {
    runnerConfig: 'e2e/jest.config.js',
    args: {
      $0: 'jest',
    },
    jest: {
      setupTimeout: 180000,
    },
  },
  apps: {
    'ios.debug': {
      type: 'ios.app',
      binaryPath: iosBinaryPath,
      build: iosBuildCmd,
    },
    'android.debug': {
      type: 'android.apk',
      binaryPath: androidBinaryPath,
      build: androidBuildCmd,
      reversePorts: [8081],
    },
  },
  devices: {
    simulator: {
      type: 'ios.simulator',
      device: {
        type: process.env.DETOX_IOS_DEVICE || 'iPhone 16',
      },
    },
    emulator: {
      type: 'android.emulator',
      device: {
        avdName: process.env.DETOX_ANDROID_AVD || 'Pixel_7_API_34',
      },
    },
  },
  configurations: {
    'ios.sim.debug': {
      device: 'simulator',
      app: 'ios.debug',
    },
    'android.emu.debug': {
      device: 'emulator',
      app: 'android.debug',
    },
  },
};
