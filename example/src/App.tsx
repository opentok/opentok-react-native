import { Text, View, StyleSheet } from 'react-native';
import { connectToSession } from 'opentok-react-native';

const apiKey = '';
const sessionId = '';
const token = '';

connectToSession(apiKey, sessionId, token);
console.log(apiKey, sessionId);

export default function App() {
  return (
    <View style={styles.container}>
      <Text>Result:</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
