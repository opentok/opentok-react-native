describe('App Launch Test', () => {
  beforeAll(async () => {
    await device.launchApp();
  });

  beforeEach(async () => {
    await device.reloadReactNative();
  });

  it('should launch the app successfully', async () => {
    await expect(element(by.text('Vonage E2E Test App'))).toBeVisible();
  });
});
