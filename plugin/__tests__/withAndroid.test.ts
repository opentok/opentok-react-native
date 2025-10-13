import { withOpentokAndroid } from "../src/withAndroid";

describe("withOpentokAndroid", () => {
  it("should add required Android permissions", () => {
    const config: any = {
      name: "TestApp",
      slug: "test-app",
    };

    const result: any = withOpentokAndroid(config, {});

    // The plugin should add withAndroidManifest
    expect(result.mods?.android?.manifest).toBeDefined();
  });

  it("should add all required permissions to AndroidManifest", async () => {
    const mockManifest = {
      manifest: {
        "uses-permission": [],
      },
    };

    const config: any = {
      name: "TestApp",
      slug: "test-app",
      modResults: mockManifest,
    };

    // Apply the plugin
    const pluginWithManifest: any = withOpentokAndroid({ ...config }, {});

    // Get the manifest modifier function
    const manifestMod = pluginWithManifest.mods?.android?.manifest;
    expect(manifestMod).toBeDefined();

    if (manifestMod) {
      // @ts-ignore
      const result = await manifestMod(config);

      const permissions = result.modResults.manifest["uses-permission"];

      // Check that required permissions were added
      expect(permissions).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            $: { "android:name": "android.permission.CAMERA" },
          }),
          expect.objectContaining({
            $: { "android:name": "android.permission.RECORD_AUDIO" },
          }),
          expect.objectContaining({
            $: { "android:name": "android.permission.INTERNET" },
          }),
          expect.objectContaining({
            $: { "android:name": "android.permission.MODIFY_AUDIO_SETTINGS" },
          }),
          expect.objectContaining({
            $: { "android:name": "android.permission.ACCESS_NETWORK_STATE" },
          }),
        ])
      );

      // Bluetooth permissions should NOT be added by default
      const hasBluetoothPermission = permissions.some(
        (p: any) => p.$?.["android:name"] === "android.permission.BLUETOOTH"
      );
      expect(hasBluetoothPermission).toBe(false);
    }
  });

  it("should add Bluetooth permissions when enabled", async () => {
    const mockManifest = {
      manifest: {
        "uses-permission": [],
      },
    };

    const config: any = {
      name: "TestApp",
      slug: "test-app",
      modResults: mockManifest,
    };

    // Apply the plugin with Bluetooth enabled
    const pluginWithManifest: any = withOpentokAndroid(
      { ...config },
      { enableBluetoothPermissions: true }
    );

    // Get the manifest modifier function
    const manifestMod = pluginWithManifest.mods?.android?.manifest;

    if (manifestMod) {
      // @ts-ignore
      const result = await manifestMod(config);

      const permissions = result.modResults.manifest["uses-permission"];

      // Check that Bluetooth permissions were added
      expect(permissions).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            $: { "android:name": "android.permission.BLUETOOTH" },
          }),
          expect.objectContaining({
            $: { "android:name": "android.permission.BLUETOOTH_CONNECT" },
          }),
        ])
      );
    }
  });

  it("should not duplicate permissions if they already exist", async () => {
    const mockManifest = {
      manifest: {
        "uses-permission": [
          { $: { "android:name": "android.permission.CAMERA" } },
          { $: { "android:name": "android.permission.INTERNET" } },
        ],
      },
    };

    const config: any = {
      name: "TestApp",
      slug: "test-app",
      modResults: mockManifest,
    };

    // Apply the plugin
    const pluginWithManifest: any = withOpentokAndroid({ ...config }, {});

    // Get the manifest modifier function
    const manifestMod = pluginWithManifest.mods?.android?.manifest;

    if (manifestMod) {
      // @ts-ignore
      const result = await manifestMod(config);

      const permissions = result.modResults.manifest["uses-permission"];

      // Count CAMERA permissions - should only be 1
      const cameraPermissions = permissions.filter(
        (p: any) => p.$?.["android:name"] === "android.permission.CAMERA"
      );
      expect(cameraPermissions).toHaveLength(1);

      // Count INTERNET permissions - should only be 1
      const internetPermissions = permissions.filter(
        (p: any) => p.$?.["android:name"] === "android.permission.INTERNET"
      );
      expect(internetPermissions).toHaveLength(1);
    }
  });
});
