import React, { useRef, useEffect } from 'react';
import { SafeAreaView, StyleSheet, Button } from 'react-native';

import {
  OTSession,
  OTSubscriber,
  OTSubscriberView,
  OTPublisher,
} from 'opentok-react-native';

function App(): React.JSX.Element {
  const apiKey = '';
  const sessionId = '';
  const token = '';

  const [subscribeToVideo, setSubscribeToVideo] = React.useState<boolean>(true);
  const [publishStream, setPublishStream] = React.useState<boolean>(true);
  const [subscribeToStreams, setSubscribeToStreams] =
    React.useState<boolean>(true);
  const [streamProperties, setStreamProperties] = React.useState<Any>({});

  const sessionRef = useRef<OTSession>(null);
  const subscriberRef = useRef<OTSubscriber>(null);
  const publisherRef = useRef<OTPublisher>(null);
  const toggleVideo = () => {
    setSubscribeToVideo((val) => !val);
  };
  const logAllEvents = false;
  const useIndividualSubscriberViews = false;
  const subscribeToSelf = false;
  const useStreamProperties = false;

  const toggleSubscribe = () => {
    setSubscribeToStreams((val) => !val);
  };

  const togglePublish = () => {
    setPublishStream((val) => !val);
  };

  useEffect(() => {
    // console.log('streamProperties updated to:', streamProperties);
  }, [streamProperties]);

  return (
    <SafeAreaView style={styles.flex1}>
      <OTSession
        apiKey={apiKey}
        token={token}
        sessionId={sessionId}
        ref={sessionRef}
        eventHandlers={{
          sessionConnected: (event: any) => {
            console.log('sessionConnected', event);
            sessionRef.current?.signal({
              type: 'greeting2',
              data: 'hello again from React Native',
            });
          },
          streamCreated: (event: any) => {
            console.log('streamCreated', event);
            setStreamProperties((prevObject: Any) => ({
              ...prevObject,
              [event.streamId]: {
                subscribeToAudio: true,
                subscribeToVideo: true,
                style: {
                  width: 240,
                  height: 180,
                },
                preferredFrameRate: 1,
                audioVolume: 0.1,
              },
            }));
          },
          streamDestroyed: (event: any) =>
            console.log('streamDestroyed', event),
          signal: (event: any) => console.log('signal event', event),
          error: (event: any) => console.log('error event', event),
          connectionCreated: (event: any) =>
            console.log('connectionCreated event', event),
          archiveStarted: (event: any) =>
            console.log('archiveStarted event', event),
          archiveStopped: (event: any) =>
            console.log('archiveStopped event', event),
          muteForced: (event: any) => console.log('muteForced event', event),
          streamPropertyChanged: (event: any) =>
            console.log('streamPropertyChanged event', event),
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
            ref={publisherRef}
            properties={{
              publishVideo: subscribeToVideo,
              publishAudio: subscribeToVideo,
              // cameraZoomFactor: 2,
              // cameraTorch: false,
              // videoTrack: true,
              // audioTrack: false,
              // audioBitrate: 8000,
              // enableDtx: true,
              name: 'OTRN',
              // videoContentHint: 'text',
            }}
            eventHandlers={{
              error: (event: any) => console.log('pub error', event),
              streamCreated: (event: any) => {
                console.log('pub streamCreated', event);
                setTimeout(() => {
                  publisherRef.current?.getRtcStatsReport();
                }, 4000);
              },
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
        {subscribeToStreams ? (
          <OTSubscriber
            key="subscriber"
            sessionId={sessionId}
            style={styles.videoview}
            subscribeToSelf={subscribeToSelf}
            properties={{
              subscribeToAudio: subscribeToVideo,
              subscribeToVideo,
              // subscribeToCaptions: true,
              // preferredFrameRate: 444,
              // audioVolume: 0.2,
            }}
            ref={subscriberRef}
            streamProperties={
              useStreamProperties ? streamProperties : undefined
            }
            eventHandlers={{
              audioLevel: (event: any) => {
                logAllEvents && console.log('sub audioLevel', event);
              },
              audioNetworkStats: (event: any) => {
                logAllEvents && console.log('sub audioNetworkStats', event);
              },
              captionReceived: (event: any) => {
                console.log('sub captionReceived', event);
              },
              disconnected: (event: any) => {
                console.log('sub disconnected', event);
              },
              error: (event: any) => {
                console.log('sub error', event);
              },
              rtcStatsReport: (event: any) => {
                console.log('sub rtcStatsReport', event);
              },
              subscriberConnected: (event: any) => {
                console.log('subscriberConnected', event);
                setTimeout(() => {
                  subscriberRef.current?.getRtcStatsReport();
                }, 4000);
              },
              videoDataReceived: (event: any) => {
                logAllEvents && console.log('sub videoDataReceived', event);
              },
              videoDisabled: (event: any) => {
                console.log('sub videoDisabled', event);
              },
              videoDisableWarning: (event: any) => {
                console.log('sub videoDisableWarning', event);
              },
              videoDisableWarningLifted: (event: any) => {
                console.log('sub videoDisableWarningLifted', event);
              },
              videoEnabled: (event: any) => {
                console.log('sub videoEnabled', event);
              },
              videoNetworkStats: (event: any) => {
                logAllEvents && console.log('sub videoNetworkStats', event);
              },
            }}
          >
            {useIndividualSubscriberViews
              ? (streamIds) => {
                  if (streamIds.length === 0) {
                    return null;
                  }
                  return streamIds.map((streamId) => {
                    return (
                      <OTSubscriberView
                        streamId={streamId}
                        key={streamId}
                        style={styles.videoview}
                      />
                    );
                  });
                }
              : null}
          </OTSubscriber>
        ) : null}
      </OTSession>
      <Button onPress={() => toggleSubscribe()} title="Toggle subscribe" />
      <Button onPress={() => togglePublish()} title="Toggle publish" />
      <Button onPress={() => toggleVideo()} title="Toggle audio/video" />
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
    width: 320,
    height: 240,
  },
  session: {
    display: 'flex',
  },
});

export default App;
