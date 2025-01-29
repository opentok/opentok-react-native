import OpentokReactNative from './NativeOpentokReactNative';

export function connectToSession(
  apiKey: string,
  sessionId: string,
  token: string
): void {
  console.log('hello');
  OpentokReactNative.initSession(apiKey, sessionId, {});
  OpentokReactNative.connect(sessionId, token);
  setTimeout(() => {
    OpentokReactNative.sendSignal(
      sessionId,
      'test-type',
      'Hello from React Native.'
    );
  }, 12000);
}
