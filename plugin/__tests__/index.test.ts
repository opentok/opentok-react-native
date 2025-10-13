import { withOpentokReactNative } from "../src/index";

describe("withOpentokReactNative", () => {
  it("should apply both iOS and Android configurations", () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
    };

    const result: any = withOpentokReactNative(config, {});

    // Plugin should add both iOS and Android mods
    expect(result.mods?.ios?.infoPlist).toBeDefined();
    expect(result.mods?.android?.manifest).toBeDefined();
  });

  it("should pass props to both platform configs", () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
    };

    const props = {
      cameraPermission: "Custom camera message",
      microphonePermission: "Custom mic message",
      enableBluetoothPermissions: true,
    };

    const result: any = withOpentokReactNative(config, props);

    // Both mods should be present
    expect(result.mods?.ios?.infoPlist).toBeDefined();
    expect(result.mods?.android?.manifest).toBeDefined();
  });

  it("should work with no props provided", () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
    };

    // Should not throw when no props provided
    expect(() => withOpentokReactNative(config, {})).not.toThrow();

    const result: any = withOpentokReactNative(config, {});

    // Both mods should still be present
    expect(result.mods?.ios?.infoPlist).toBeDefined();
    expect(result.mods?.android?.manifest).toBeDefined();
  });

  it("should work with empty props object", () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
    };

    const result: any = withOpentokReactNative(config, {});

    // Both mods should be present
    expect(result.mods?.ios?.infoPlist).toBeDefined();
    expect(result.mods?.android?.manifest).toBeDefined();
  });

  it("should preserve existing config properties", () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
      version: "1.0.0",
      extra: {
        customData: "test",
      },
    };

    const result: any = withOpentokReactNative(config, {});

    // Existing properties should be preserved
    expect(result.name).toBe("TestApp");
    expect(result.slug).toBe("test-app");
    expect(result.version).toBe("1.0.0");
    expect(result.extra?.customData).toBe("test");
  });

  it("should handle partial props", () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
    };

    // Only provide camera permission
    const result1: any = withOpentokReactNative(config, {
      cameraPermission: "Custom camera only",
    });

    expect(result1.mods?.ios?.infoPlist).toBeDefined();
    expect(result1.mods?.android?.manifest).toBeDefined();

    // Only provide Bluetooth flag
    const result2: any = withOpentokReactNative(config, {
      enableBluetoothPermissions: true,
    });

    expect(result2.mods?.ios?.infoPlist).toBeDefined();
    expect(result2.mods?.android?.manifest).toBeDefined();
  });
});
