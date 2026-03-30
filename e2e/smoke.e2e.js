describe('E2E smoke', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  it('launches the app', async () => {
    await expect(device).toBeDefined();
  });
});
