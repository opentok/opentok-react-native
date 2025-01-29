import React from 'react';
import { SafeAreaView, StyleSheet, Text } from 'react-native';

import { OTSessionManager } from 'opentok-react-native';

function App(): React.JSX.Element {
  const apiKey = '';
  const sessionId =
    '';
  const token =
    '';

  React.useEffect(() => {
    OTSessionManager.initSession(apiKey, sessionId, {});
    OTSessionManager.connect(sessionId, token);
    OTSessionManager.onSessionConnected((event: any) =>
      console.log('sessionConnected', event)
    );
    setTimeout(() => {
      OTSessionManager.sendSignal(
        sessionId,
        'test-type',
        'Hello from React Native.'
      );
    }, 12000);
  }, []);

  return (
    <SafeAreaView style={styles.flex1}>
      <Text style={styles.text}>sessionId: {sessionId}</Text>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  flex1: { flex: 1 },
  text: {
    margin: 10,
    fontSize: 20,
  },
  webview: {
    width: '50%',
    height: '50%',
  },
  session: {
    display: 'flex',
  },
});

export default App;
