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

  it('should connect and disconnect a session', async () => {
    // Initial state: session inactive
    await expect(element(by.id('session-state'))).toHaveText('Session Inactive');

    // Tap connect button
    await element(by.id('start-session-btn')).tap();

    // Wait a few seconds for the session to establish
    await new Promise((resolve) => setTimeout(resolve, 3000));

    // Verify session is active
    await expect(element(by.id('session-state'))).toHaveText('Session Active');

    // Tap disconnect button
    await element(by.id('stop-session-btn')).tap();

    // Verify session is inactive again
    await expect(element(by.id('session-state'))).toHaveText('Session Inactive');
  });
});
