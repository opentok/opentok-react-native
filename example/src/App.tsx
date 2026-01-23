import React, { useRef, useEffect } from 'react';
import { StyleSheet, Button } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import {
  OTSession,
  OTSubscriber,
  OTPublisher,
  type StreamCreatedEvent,
} from '@vonage/client-sdk-video-react-native';

function App(): React.JSX.Element {
  const applicationId = '';
  const sessionId = '';
  const token = '';
  const sessionId2 = '';
  const token2 = '';

  const [subscribeToVideo, setSubscribeToVideo] = React.useState<boolean>(true);
  const [publishStream, setPublishStream] = React.useState<boolean>(true);
  const [subscribeToStreams, setSubscribeToStreams] =
    React.useState<boolean>(true);
  const [streamProperties, setStreamProperties] = React.useState<any>({});
  const [signalProp, setSignalProp] = React.useState<any>({
    type: 'greeting2',
    data: 'initial signal from React Native',
  });

  const sessionRef = useRef<OTSession>(null);
  const subscriberRef = useRef<OTSubscriber>(null);
  const publisherRef = useRef<OTPublisher>(null);
  const toggleVideo = () => {
    setSubscribeToVideo((val) => !val);
  };
  const logAllEvents = false;
  const subscribeToSelf = false;
  const useStreamProperties = false;

  const toggleSubscribe = () => {
    setSubscribeToStreams((val) => !val);
  };

  const togglePublish = () => {
    setPublishStream((val) => !val);
  };

  useEffect(() => {
    console.log('streamProperties updated to:', streamProperties);
  }, [streamProperties]);

  return (
    <SafeAreaView style={styles.flex1}>
      <OTSession
        applicationId={applicationId}
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
            sessionRef.current
              ?.getCapabilities()
              .then((capabilities) =>
                console.log('capabilities:', capabilities)
              );
            sessionRef.current
              ?.reportIssue()
              .then((id: any) => console.log('reportIssue ID', id))
              .catch((error: any) => console.log('reportIssue error', error));
            sessionRef.current
              ?.getCapabilities()
              .then((id: any) => console.log('Session.getCapabilities()', id))
              .catch((error: any) =>
                console.log('Session.getCapabilities() error', error)
              );
            setTimeout(() => {
              sessionRef.current?.signal({
                type: 'internalGreeting',
                data: 'hello to myself only',
                to: event.connectionId,
              });
              setSignalProp({
                type: 'greeting2',
                data: 'another signal from React Native (via prop)',
              });
            }, 1000);
          },
          streamCreated: (event: any) => {
            console.log('streamCreated', event);
            setStreamProperties((prevObject: any) => ({
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
          connectionCreated: (event: any) => {
            console.log('connectionCreated', event);
            sessionRef.current?.signal({
              to: event.connectionId,
              data: `wecome to the session, connection ${event.connectionId}`,
              type: 'connectionGreeting',
            });
          },
          connectionDestroyed: (event: any) =>
            console.log('connectionDestroyed', event),
          archiveStarted: (event: any) =>
            console.log('archiveStarted event', event),
          archiveStopped: (event: any) =>
            console.log('archiveStopped event', event),
          muteForced: (event: any) => console.log('muteForced event', event),
          streamPropertyChanged: (event: any) =>
            console.log('streamPropertyChanged event', event),
        }}
        signal={signalProp}
        style={styles.session}
      >
        {publishStream ? (
          <OTPublisher
            key="publisher"
            ref={publisherRef}
            properties={{
              publishVideo: subscribeToVideo,
              publishAudio: subscribeToVideo,
              allowAudioCaptureWhileMuted: true,
              name: 'OTRN',
            }}
            eventHandlers={{
              error: (event: any) => {
                console.log('pub error', event);
              },
              streamCreated: (event: StreamCreatedEvent) => {
                console.log('pub streamCreated', event);
                setTimeout(() => {
                  publisherRef.current?.getRtcStatsReport();
                }, 5000);
              },
              streamDestroyed: (event: any) => {
                console.log('pub streamDestroyed', event);
              },
              audioLevel: (level: number) => {
                logAllEvents && console.log('pub audioLevel', level);
              },
              audioNetworkStats: (event: any) => {
                logAllEvents && console.log('pub audioNetworkStats', event);
              },
              rtcStatsReport: (event: any) => {
                logAllEvents && console.log('pub rtcStatsReport', event);
              },
              videoDisabled: (event: any) => {
                console.log('pub videoDisabled', event);
              },
              videoDisableWarning: () => {
                console.log('pub videoDisableWarning');
              },
              videoDisableWarningLifted: () => {
                console.log('pub videoDisableWarningLifted');
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
              disconnected: () => {
                console.log('sub disconnected');
              },
              error: (event: any) => {
                console.log('sub error', event);
              },
              rtcStatsReport: (event: any) => {
                logAllEvents && console.log('sub rtcStatsReport', event);
              },
              videoDataReceived: () => {
                logAllEvents && console.log('sub videoDataReceived');
              },
              videoDisabled: (event: any) => {
                console.log('sub videoDisabled', event);
              },
              videoDisableWarning: () => {
                console.log('sub videoDisableWarning');
              },
              videoDisableWarningLifted: () => {
                console.log('sub videoDisableWarningLifted');
              },
              videoEnabled: (event: any) => {
                console.log('sub videoEnabled', event);
              },
              videoNetworkStats: (event: any) => {
                logAllEvents && console.log('sub videoNetworkStats', event);
              },
            }}
          ></OTSubscriber>
        ) : null}
      </OTSession>
      {sessionId2 ? (
        <OTSession
          applicationId={applicationId}
          sessionId={sessionId2}
          token={token2}
          eventHandlers={{
            error: (e) => console.log('s2 error', e),
            sessionConnected: (e) => console.log('s2 connected', e),
            signal: (e) => console.log('s2 signal', e),
            connectionCreated: (e) => console.log('s2 connectionCreated', e),
            streamCreated: (e) => console.log('s2 streamCreated', e),
          }}
          signal={{
            type: 'session2',
            data: 'signal from React Native session 2',
          }}
        >
          <OTSubscriber style={styles.videoview} />
        </OTSession>
      ) : null}
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
