# Event data

You can register event handler functions with the `eventHandlers` property of the
OTSession, OTPublisher, and OTSubscriber components:

```javascript
class App extends Component {
  constructor(props) {
    super(props);

    this.sessionEventHandlers = {
      streamCreated: event => {
        console.log('Stream created!', event);
      },
      streamDestroyed: event => {
        console.log('Stream destroyed!', event);
      },
      sessionConnected: event => {
        console.log('Connected to the session!');
      },
      sessionDisconnected: event => {
        console.log('Disconnected from the session!');
      }
    };

    this.subscriberEventHandlers = {
      streamCreated: event => {
        console.log('Stream created!', event);
      },
      streamDestroyed: event => {
        console.log('Stream destroyed!', event);
      },
      sessionConnected: event => {
        this.setState({
          isConnected: true,
        })
      }
    };
  }

  render() {
    return (
      <OTSession apiKey="your-api-key" sessionId="your-session-id" token="your-session-token" eventHandlers={this.sesssionEventHandlers}>
        <OTPublisher eventHandlers={this.publisherEventHandlers}/>
        <OTSubscriber eventHandlers={this.suscriberEventHandlers} />
      </OTSession>
    );
  }
}
```

The following sections define the structure of different event objects.

## ArchiveEvent

The OTSession object dispatches `archiveStarted` and `archiveStopped` events
when an [archive](https://tokbox.com/developer/guides/archiving) starts and stops
for a session. The event object has the following properties: 

```javascript
  archive = {
    archiveId: string, // The archive ID.
    name: string, // The archive name.
    sessionId: string, // The session ID.
  };
```

## AudioNetworkStats

To get audio data for a subscriber, register an event listener for the `audioNetworkStats` event.
The event object has the following properties: 

```javascript
  event = {
    audioBytesReceived: number,
    audioPacketsLost: number,
    audioPacketsReceived: number,
    timeStamp: number,
  };
```

## ConnectionCreatedEvent

You can find the structure of the object below: 

```javascript
  event = {
    sessionId: string;
    connection = {
      connectionId: string
      creationTime: string,
      data: string,
    }
  }
```

## ConnectionDestroyedEvent

You can find the structure of the object below: 

```javascript
  event = {
    sessionId: string;
    connection = {
      connectionId: string
      creationTime: string,
      data: string,
    }
  }
```

## ErrorEvent

You can find the structure of the object below: 

```javascript
  event = {
    code: string,
    message: string,
  };
```

## PublisherVideoNetworkStatsEvent

To get video data for a publisher, register an event listener for the OTPublisher
`videoNetworkStats` event. The object has the following structure: 

```javascript
  event = [
      {
      connectionId: string,
      subscriberId: string,
      videoPacketsLost: number,
      videoBytesSent: number,
      videoPacketsSent: number,
      timestamp: number,
    }
  ];
```

Note that this event object is an array of objects. See the docs for
the OTPublisher `videoNetworkStats` event.

## PublisherAudioNetworkStatsEvent

To get audio data for a publisher, register an event listener for the OTPublisher
`audioNetworkStats` event. The object has the following structure: 

```javascript
  event = [
      {
      connectionId: string,
      subscriberId: string,
      audioPacketsLost: number,
      audioPacketsSent: number,
      audioPacketsSent: number,
      timestamp: number,
    }
  ];
```

Note that this event object is an array of objects. See the docs for
the OTPublisher `audioNetworkStats` event.

## RtcStatsReportEvent
You can find the structure of the object below:

```javascript
  event = {
    connectionId: string,
    jsonArrayOfReports: string,
  };
```

## SessionConnectEvent

```javascript
event = {
  sessionId: string;
  connection: {
    connectionId: string,
    creationTime: string,
    data: string,
  },
}
```

## SessionDisconnectEvent

```javascript
event = {
  sessionId: string;
}
```

## SignalEvent

The OTSession object dispatches a `signal` event when a signal is received.
See the [signaling developer guide](https://tokbox.com/developer/guides/signaling/).
The event object has the following properties: 

```javascript
  event = {
    type: string, // Either 'signal' or 'signal:type'.
    data: string, // The data.
    connectionId: string, // The connection ID of the client that sent the signal.
  };
```

## StreamCreatedEvent

You can find the structure of the object below: 

```javascript
  stream = {
    streamId: string;
    name: string;
    connectionId: string, // This will be removed after v0.11.0 because it's exposed via the connection object
    connection: {
      connectionId: string,
      creationTime: string,
      data: string,
    },
    hasAudio: boolean,
    hasVideo: boolean,
    sessionId: string,
    creationTime: number,
    height: number,
    width: number,
    videoType: string, // 'camera' or 'screen'
  };
```

## StreamDestroyedEvent

```javascript
  event = {
    streamId: string;
    name: string;
    connectionId: string;
    connection: {
      connectionId: string,
      creationTime: string,
      data: string,
    },
    hasAudio: boolean,
    hasVideo: boolean,
    sessionId: string,
    creationTime: number,
    height: number,
    width: number,
    videoType: string, // 'camera' or 'screen'
  };
```

## StreamPropertyChangedEvent

```javascript
  event = {
    stream: {
      streamId: string,
      name: string,
      connectionId: string, // This will be removed after v0.11.0 because it's exposed via the connection object
      connection: {
        connectionId: string,
        creationTime: number,
        data: string,
      },
      hasAudio: boolean,
      hasVideo: boolean,
      sessionId: string,
      creationTime: number,
      height: number,
      width: number,
      videoType: string, // 'camera' or 'screen'
    },
    oldValue: any,
    newValue: any,
    changedProperty: string,
  };
```

## SubscriberAudioLevelEvent

```javascript
  event = {
    audioLevel: number;
    stream: {
      streamId: string,
      name: string,
      connectionId: string, // This will be removed after v0.11.0 because it's exposed via the connection object
      connection: {
        connectionId: string,
        creationTime: number,
        data: string,
      },
      hasAudio: boolean,
      hasVideo: boolean,
      sessionId: string,
      creationTime: number,
      height: number,
      width: number,
      videoType: string, // 'camera' or 'screen'
    },
  };
```

## VideoNetworkStatsEvent
You can find the structure of the object below:

```javascript
  event = {
    videoPacketsLost: number,
    videoBytesReceived: number,
    videoPacketsReceived: number,
    timestamp: number
  };
```

## SubscriberRtcStatsReportEvent

```javascript
  event = {
    stream: {
      streamId: string;
      name: string;
      connectionId: string;
      connection: {
        connectionId: string,
        creationTime: string,
        data: string,
      },
      hasAudio: boolean,
      hasVideo: boolean,
      sessionId: string,
      creationTime: number,
      height: number,
      width: number,
      videoType: string, // 'camera' or 'screen'
    },
    jsonArrayOfReports: string
  };
```

## PublisherRtcStatsReportEvent

```javascript
  event = [
    connectionId: string
    jsonArrayOfReports: string
  ];
```
