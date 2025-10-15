import { withOpentokIOS } from "../src/withIOS";

describe("withOpentokIOS", () => {
  it("should add default camera and microphone usage descriptions", async () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
      modResults: {},
    };

    // Apply the plugin
    const pluginWithInfoPlist: any = withOpentokIOS({ ...config }, {});

    // Get the Info.plist modifier function
    const infoPlistMod = pluginWithInfoPlist.mods?.ios?.infoPlist;
    expect(infoPlistMod).toBeDefined();

    if (infoPlistMod) {
      // @ts-ignore
      const result = await infoPlistMod(config);

      const infoPlist = result.modResults;

      // Check that usage descriptions were added with default values
      expect(infoPlist.NSCameraUsageDescription).toBe(
        "Allow $(PRODUCT_NAME) to access your camera for video calls."
      );
      expect(infoPlist.NSMicrophoneUsageDescription).toBe(
        "Allow $(PRODUCT_NAME) to access your microphone for audio calls."
      );
    }
  });

  it("should use custom camera permission message", async () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
      modResults: {},
    };

    const customCameraMessage = "We need camera access for video chat";

    // Apply the plugin with custom message
    const pluginWithInfoPlist: any = withOpentokIOS(
      { ...config },
      { cameraPermission: customCameraMessage }
    );

    // Get the Info.plist modifier function
    const infoPlistMod = pluginWithInfoPlist.mods?.ios?.infoPlist;

    if (infoPlistMod) {
      // @ts-ignore
      const result = await infoPlistMod(config);

      const infoPlist = result.modResults;

      // Check that custom message was used
      expect(infoPlist.NSCameraUsageDescription).toBe(customCameraMessage);
    }
  });

  it("should use custom microphone permission message", async () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
      modResults: {},
    };

    const customMicMessage = "We need microphone access for audio chat";

    // Apply the plugin with custom message
    const pluginWithInfoPlist: any = withOpentokIOS(
      { ...config },
      { microphonePermission: customMicMessage }
    );

    // Get the Info.plist modifier function
    const infoPlistMod = pluginWithInfoPlist.mods?.ios?.infoPlist;

    if (infoPlistMod) {
      // @ts-ignore
      const result = await infoPlistMod(config);

      const infoPlist = result.modResults;

      // Check that custom message was used
      expect(infoPlist.NSMicrophoneUsageDescription).toBe(customMicMessage);
    }
  });

  it("should use both custom permission messages", async () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
      modResults: {},
    };

    const customCameraMessage = "Custom camera message";
    const customMicMessage = "Custom microphone message";

    // Apply the plugin with custom messages
    const pluginWithInfoPlist: any = withOpentokIOS(
      { ...config },
      {
        cameraPermission: customCameraMessage,
        microphonePermission: customMicMessage,
      }
    );

    // Get the Info.plist modifier function
    const infoPlistMod = pluginWithInfoPlist.mods?.ios?.infoPlist;

    if (infoPlistMod) {
      // @ts-ignore
      const result = await infoPlistMod(config);

      const infoPlist = result.modResults;

      // Check that both custom messages were used
      expect(infoPlist.NSCameraUsageDescription).toBe(customCameraMessage);
      expect(infoPlist.NSMicrophoneUsageDescription).toBe(customMicMessage);
    }
  });

  it("should preserve existing Info.plist entries", async () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
      modResults: {
        CFBundleDisplayName: "Test App",
        CFBundleVersion: "1.0.0",
        UIRequiredDeviceCapabilities: ["armv7"],
      },
    };

    // Apply the plugin
    const pluginWithInfoPlist: any = withOpentokIOS({ ...config }, {});

    // Get the Info.plist modifier function
    const infoPlistMod = pluginWithInfoPlist.mods?.ios?.infoPlist;

    if (infoPlistMod) {
      // @ts-ignore
      const result = await infoPlistMod(config);

      const infoPlist = result.modResults;

      // Check that existing entries are preserved
      expect(infoPlist.CFBundleDisplayName).toBe("Test App");
      expect(infoPlist.CFBundleVersion).toBe("1.0.0");
      expect(infoPlist.UIRequiredDeviceCapabilities).toEqual(["armv7"]);

      // And new entries were added
      expect(infoPlist.NSCameraUsageDescription).toBeDefined();
      expect(infoPlist.NSMicrophoneUsageDescription).toBeDefined();
    }
  });

  it("should preserve existing permission descriptions when no custom props provided", async () => {
    const existingCameraDescription = "Existing camera description";
    const existingMicDescription = "Existing microphone description";

    const config: any = {
      name: "TestApp",
      slug: "test-app",
      modResults: {
        NSCameraUsageDescription: existingCameraDescription,
        NSMicrophoneUsageDescription: existingMicDescription,
      },
    };

    // Apply the plugin without custom props
    const pluginWithInfoPlist: any = withOpentokIOS({ ...config }, {});

    // Get the Info.plist modifier function
    const infoPlistMod = pluginWithInfoPlist.mods?.ios?.infoPlist;

    if (infoPlistMod) {
      // @ts-ignore
      const result = await infoPlistMod(config);

      const infoPlist = result.modResults;

      // Check that existing descriptions are preserved
      expect(infoPlist.NSCameraUsageDescription).toBe(existingCameraDescription);
      expect(infoPlist.NSMicrophoneUsageDescription).toBe(existingMicDescription);
    }
  });

  it("should override existing permission descriptions when custom props provided", async () => {
    const existingCameraDescription = "Existing camera description";
    const existingMicDescription = "Existing microphone description";
    const customCameraMessage = "Custom camera message";
    const customMicMessage = "Custom microphone message";

    const config: any = {
      name: "TestApp",
      slug: "test-app",
      modResults: {
        NSCameraUsageDescription: existingCameraDescription,
        NSMicrophoneUsageDescription: existingMicDescription,
      },
    };

    // Apply the plugin with custom props
    const pluginWithInfoPlist: any = withOpentokIOS(
      { ...config },
      {
        cameraPermission: customCameraMessage,
        microphonePermission: customMicMessage,
      }
    );

    // Get the Info.plist modifier function
    const infoPlistMod = pluginWithInfoPlist.mods?.ios?.infoPlist;

    if (infoPlistMod) {
      // @ts-ignore
      const result = await infoPlistMod(config);

      const infoPlist = result.modResults;

      // Check that custom descriptions override existing ones
      expect(infoPlist.NSCameraUsageDescription).toBe(customCameraMessage);
      expect(infoPlist.NSMicrophoneUsageDescription).toBe(customMicMessage);
    }
  });
});