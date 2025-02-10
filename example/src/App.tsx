import React, {useRef} from 'react';
import {
  SafeAreaView,
  StyleSheet,
  Text,
} from 'react-native';

import { OTSession } from 'opentok-react-native';

function App(): React.JSX.Element {
  const apiKey = '';
  const sessionId = '';
  const token = '';

  const [streamIds, setStreamIds] = React.useState<string[]>([]);
  const [subscribeToVideo, setSubscribeToVideo] = React.useState<boolean>(true);

  const sessionRef = useRef<OTSession>(null);
  const toggleVideo = () => {
    setSubscribeToVideo(val => !val);
  };

  React.useEffect(() => {
    setInterval(() => {
      toggleVideo();
    }, 2000);
  }, []);

  return (
    <SafeAreaView style={{flex: 1}}>
      <Text style={styles.text}>
        SubscribeToVideo: {subscribeToVideo.toString()}
      </Text>
      <OTSession
        apiKey={apiKey}
        token={token}
        sessionId={sessionId}
        ref={sessionRef}
        eventHandlers={{
          sessionConnected: (event:any) => {
            console.log('sessionConnected', event);
            sessionRef.current?.signal({
              type: 'greeting2',
              data: 'hello again from React Native'
            });
        },
          streamCreated: (event:any) => {
            console.log('streamCreated', event);
            setStreamIds(prevIds => [...prevIds, event.streamId]);
          },
          streamDestroyed: (event:any) => console.log('streamDestroyed', event),
          signal: (event:any) => console.log('signal event', event),
          error: (event:any) => console.log('error event', event),
        }}
        signal={{
          type: 'greeting2',
          data: 'initial signal from React Native'
        }}
        style={styles.session}
      >
        {streamIds?.map((streamId) => <Text
          style={styles.text}
          key={streamId}>
          Stream: {streamId}
        </Text>)}
        </OTSession>
      <Text style={styles.text}>
        Stream count: {streamIds.length.toString()}
      </Text>

    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  text: {
    margin: 10,
    fontSize: 20,
  },
  webview: {
    width: '50%',
    height: '50%',
  },
  session: {
    display: "flex"
  }
});

export default App;
