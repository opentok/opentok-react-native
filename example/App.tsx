import { useMemo, useState } from 'react';
import { SafeAreaView, StyleSheet, Text, TouchableOpacity } from 'react-native';
import { OTSession } from '../src';

function App() {
  const [joined, setJoined] = useState(false);

  const creds = useMemo(
    () => ({
      applicationId: '',
      sessionId: '',
      token: '',
    }),
    []
  );

  return (
    <SafeAreaView style={styles.screen}>
      <Text style={styles.title}>Vonage E2E Test App</Text>

      <TouchableOpacity
        testID="start-session-btn"
        onPress={() => setJoined(true)}
        style={styles.button}
      >
        <Text style={styles.buttonText}>Create Session + Publisher + Subscriber</Text>
      </TouchableOpacity>

      <TouchableOpacity
        testID="stop-session-btn"
        onPress={() => setJoined(false)}
        style={[styles.button, styles.secondaryButton]}
      >
        <Text style={styles.buttonText}>Stop Session</Text>
      </TouchableOpacity>

      <Text testID="session-state" style={styles.stateText}>
        {joined ? 'Session Active' : 'Session Inactive'}
      </Text>

      {joined ? (
        <OTSession
          applicationId={creds.applicationId}
          sessionId={creds.sessionId}
          token={creds.token}
        >
          <Text>Test</Text>
        </OTSession>
      ) : null}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    padding: 24,
    backgroundColor: '#111827',
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#ffffff',
    marginBottom: 16,
  },
  button: {
    backgroundColor: '#2563eb',
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderRadius: 8,
    marginBottom: 10,
  },
  secondaryButton: {
    backgroundColor: '#4b5563',
  },
  buttonText: {
    color: '#ffffff',
    fontWeight: '600',
  },
  stateText: {
    color: '#d1d5db',
    marginTop: 6,
    marginBottom: 16,
  },
  videoRow: {
    flexDirection: 'row',
    gap: 12,
  },
  videoTile: {
    width: 160,
    height: 220,
    backgroundColor: '#1f2937',
  },
});

export default App;
