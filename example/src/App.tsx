import React, { useRef } from 'react';
import { SafeAreaView, StyleSheet, Text, View } from 'react-native';

import { OTSession, OTSubscriberView, OTPublisher } from 'opentok-react-native';

function App(): React.JSX.Element {
  const apiKey = '';
  const sessionId = '';
  const token = '';

  const [streamIds, setStreamIds] = React.useState<string[]>([]);
  const [subscribeToVideo, setSubscribeToVideo] = React.useState<boolean>(true);
  const [publishStream, setPublishStream] = React.useState<boolean>(false);

  const sessionRef = useRef<OTSession>(null);
  const subscriberRef = useRef<OTSubscriberViewNative>(null);
  const toggleVideo = () => {
    setSubscribeToVideo((val) => !val);
  };
  const logAllEvents = false;

  React.useEffect(() => {
    setInterval(() => {
      toggleVideo();
    }, 2000);
  }, []);

  return (
    <SafeAreaView style={styles.flex1}>
      <Text style={styles.text}>
        SubscribeToVideo: {subscribeToVideo.toString()}
      </Text>
      <OTSession
        apiKey={apiKey}
        token={token}
        sessionId={sessionId}
        ref={sessionRef}
        eventHandlers={{
          sessionConnected: (event: any) => {
            console.log('sessionConnected', event);
            setTimeout(() => setPublishStream(true), 5000);
            sessionRef.current?.signal({
              type: 'greeting2',
              data: 'hello again from React Native',
            });
          },
          streamCreated: (event: any) => {
            console.log('streamCreated', event);
            setStreamIds((prevIds) => [...prevIds, event.streamId]);
          },
          streamDestroyed: (event: any) =>
            console.log('streamDestroyed', event),
          signal: (event: any) => console.log('signal event', event),
          error: (event: any) => console.log('error event', event),
        }}
        signal={{
          type: 'greeting2',
          data: 'initial signal from React Native',
        }}
        style={styles.session}
      >
        {publishStream ? (
          <OTPublisher
            sessionId={sessionId}
            key="publisher"
            properties={{
              publishVideo: subscribeToVideo,
            }}
            eventHandlers={{
              error: (event: any) => console.log('pub error', event),
              streamCreated: (event: any) =>
                console.log('pub streamCreated', event),
              streamDestroyed: (event: any) =>
                console.log('pub streamDestroyed', event),
              audioLevel: (event: any) => {
                logAllEvents && console.log('pub audioLevel', event);
              },
              audioNetworkStats: (event: any) => {
                logAllEvents && console.log('pub audioNetworkStats', event);
              },
              rtcStatsReport: (event: any) => {
                console.log('pub rtcStatsReport', event);
              },
              videoDisabled: (event: any) => {
                console.log('pub videoDisabled', event);
              },
              videoDisableWarning: (event: any) => {
                console.log('pub videoDisableWarning', event);
              },
              videoDisableWarningLifted: (event: any) => {
                console.log('pub videoDisableWarningLifted', event);
              },
              videoEnabled: (event: any) => {
                console.log('pub videoEnabled', event);
              },
              videoNetworkStats: (event: any) => {
                logAllEvents && console.log('pub videoNetworkStats', event);
              },
            }}
            style={styles.videoview}
          />
        ) : null}

        <View key="subscriber" style={styles.subscriber}>
          {streamIds?.map((streamId) => (
            <OTSubscriberView
              streamId={streamId}
              sessionId={sessionId}
              key={streamId}
              ref={subscriberRef}
              subscribeToVideo={subscribeToVideo}
              subscribeToAudio={!subscribeToVideo}
              style={styles.videoview}
              eventHandlers={{
                subscriberConnected: (event: any) => {
                  console.log('subscriberConnected', event);
                  setTimeout(() => {
                    subscriberRef.current?.getRtcStatsReport();
                  }, 4000);
                },
                onRtcStatsReport: (event: any) => {
                  console.log('onRtcStatsReport', event);
                },
              }}
            />
          ))}
        </View>
      </OTSession>
      <Text style={styles.text}>
        Stream count: {streamIds.length.toString()}
      </Text>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  flex1: { flex: 1 },
  text: {
    margin: 10,
    fontSize: 20,
  },
  videoview: {
    width: '50%',
    height: '50%',
  },
  session: {
    display: 'flex',
  },
  subscriber: {
    display: 'flex',
  },
});

export default App;
