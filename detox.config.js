module.exports = {
  apps: {
    'ios.debug': {
      type: 'ios.app',
      binaryPath: '/Users/iperunovic/Code/vonage-video-react-native-sdk/example/ios/build/Build/Products/Debug-iphonesimulator/E2ETestApp.app',
      build: "xcodebuild -workspace /Users/iperunovic/Code/vonage-video-react-native-sdk/example/ios/E2ETestApp.xcworkspace -scheme 'E2ETestApp (E2ETestApp Workspace)' -configuration Debug -derivedDataPath /Users/iperunovic/Code/vonage-video-react-native-sdk/example/ios/build -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' ARCHS=arm64 ONLY_ACTIVE_ARCH=YES SWIFT_ENABLE_EXPLICIT_MODULES=NO",
    },
  },
  devices: {
    simulator: {
      type: 'ios.simulator',
      device: {
        type: 'iPhone 17',
      },
    },
  },
  configurations: {
    'ios.sim.debug': {
      device: 'simulator',
      app: 'ios.debug',
    },
  },
};
