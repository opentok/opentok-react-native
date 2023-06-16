# OTSession Component

The `OTSession` component manages the connection to an OpenTok Session. It passes the session ID to the
`sessionId` property to its child components. To disconnect the session, unmount the `OTSession` component.
To publish and subscribe, you must nest `OTPublisher` and `OTSubscriber` inside `OTSession`:

```javascript
class App extends Component {
  constructor(props) {
    super(props);

    this.state = {
      isConnected: false,
    };

    this.otSessionRef = React.createRef();

    this.sessionEventHandlers = {
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

  sendSignal = () => {
    if (this.state.isConnected) {
      this.otSessionRef.current.signal({
        data: 'hello',
        to: '6d26ca65-24c9-45df-b827-424e9952dece', // optional - connection ID of client to recieve the signal
        type: 'greeting', // optional
      })
    }
  }

  render() {
    return (
      <OTSession apiKey="your-api-key" sessionId="your-session-id" token="your-session-token" eventHandlers={this.sesssionEventHandlers} ref={this.otSessionRef}>
        <OTPublisher style={{ width: 100, height: 100 }}/>
        <OTSubscriber style={{ width: 100, height: 100 }} />
      </OTSession>
    );
  }
}
```

You can set the session options using the `options` prop:

```javascript
class App extends Component {
constructor(props) {
  super(props);
  this.sessionOptions = {
    connectionEventsSuppressed: true, // default is false
    androidZOrder: '', // Android only - valid options are 'mediaOverlay' or 'onTop'
    androidOnTop: '',  // Android only - valid options are 'publisher' or 'subscriber'
    useTextureViews: true,  // Android only - default is false
    ipWhitelist: false, // https://tokbox.com/developer/sdks/js/reference/OT.html#initSession - ipWhitelist
    enableStereoOutput: true // Enable stereo output, default is false
    iceConfig:{
      transportPolicy: 'all', // Valid options are 'all' or 'relay'. Default is 'all'
      includeServers: 'all', // Valid options are 'all' or 'custom'. Default is 'all'
      customServers: [
        {
        urls: [
          'turn:123.124.125.126:3478?transport=udp',
          'turn:123.124.125.126:3478?transport=tcp'
        ],
        username: 'webrtc',
        credential: 'foO0Bar1'
        },
      ],
    },
  };
}

render() {
  return (
    <OTSession apiKey="your-api-key" sessionId="your-session-id" token="your-session-token" options={this.sessionOptions}>
      <OTPublisher style={{ width: 100, height: 100 }}/>
      <OTSubscriber style={{ width: 100, height: 100 }} />
    </OTSession>
  );
}
}
```

Please note that all session options are optional. See [Session options](#session-options).

## Properties

The OTSession object has the following properties:

**apiKey** (String, required) -- The OpenTok project API key.

**sessionId** (String, required) -- The OpenTok session ID.

**token** (String, required) -- The OpenTok token for the client.

**options** (Object, optional) -- Used to define session options. See [Session options](session-options).

**signal** (Object, optional) -- Used to send a signal to the session

**eventHandlers** (Object, optional) -- An object containing key-value pairs of event names and
callback functions for event handlers. See [Events](#events).

## Session options

**androidZOrder** (String) -- Set to "mediaOverlay" or "onTop". Android only.

**androidOnTop** (String) -- Set to "publisher" | "subscriber". Android only.

**connectionEventsSuppressed** (Boolean) -- Whether to prevent `connectionCreated` and
`connectionDestroyed` event from being dispatched. You may want to suppress these events in
large sessions, such as those used for
[live interactive video broadcasts](https://tokbox.com/developer/guides/broadcast/live-interactive-video/#suppressing-connection-events).
The default value is false.

**enableStereoOutput** (Boolean) -- Whether to enable stereo output. The default value is false.

**iceConfig** (Object) -- Settings for using the
[configurable TURN feature](https://tokbox.com/developer/guides/configurable-turn-servers/).
This feature is available as an [add-on feature](https://tokbox.com/pricing/plans).

This object has the following properties:

  * `includeServers` (String) Whether the client should use your TURN servers exclusively ('custom')
    or use them in addition to the OpenTok TURN servers ('all').

  * `transportPolicy` 'all' | 'relay';

  * `customServers` (Array) -- An array of objects defining custom TURN servers to use.
    Each object has the following properties:

    - `urls` (Array of strings) -- The URLs of the TURN server.
    - `username` (String, optional) -- The user name.
    - `credential`: (String, optional) -- The credential for the TURN server.

**ipWhitelist** (Boolean) -- Whether to use the
[allowed IP list](https://tokbox.com/developer/guides/ip-addresses/) feature.
This is available as an [add-on feature](https://www.vonage.com/communications-apis/video/pricing//plans)
The default value is false.

**isCamera2Capable** (Boolean) -- Deprecated and ignored. Android only.

**proxyUrl** (String) -- The proxy URL to use for the session.
This is an [add-on feature](https://www.vonage.com/communications-apis/video/pricing//plans)
feature. See the [OpenTok IP Proxy](https://tokbox.com/developer/guides/ip-proxy/) developer guide.

**useTextureViews** (Boolean) -- Set to `true` to use texture views. The default is `false`. Android only.

## Methods

**getSessionInfo()** Returns an object with the following properties:

* `sessionId` (String) -- The session ID.

* `connection` (Object) -- An object defining the local client's connection to the session. 
  This includes the following properties:

  - `connectionId` (String) -- The local client's connection ID.

  - `creationTime`(String) -- The time the connection was created.

  - `data` (String) -- The [connection data](https://tokbox.com/developer/guides/create-token/#connection-data)
    for the local client.

**signal()** Sends a signal to clients connected to the session. The method has one parameter,
an object that includes the following properties, each of which is optional
(although you usually want to set the `data` property):

* `connectionId` (String) -- The connection ID of the client to send the signal to. If this
  is omitted, the signal is sent to all clients connected to the session.

* `type` (string) -- The signal type.

* `data` (string) -- The signal data.

For more information, see the
[OpenTok signaling developer guide](https://tokbox.com/developer/guides/signaling/)

## Events

**archiveStarted** (Object) — Sent when an archive recording of a session starts. If you connect to a session in which recording is already in progress, this message is sent when you connect.
An [ArchiveEvent](./EventData.md#ArchiveEvent) object is passed into the event handler.

**archiveStopped** (String) — Sent when an archive recording of a session stops.
An [ArchiveEvent](./EventData.md#ArchiveEvent) object is passed into the event handler.

**connectionCreated** (Object) — Sent when another client connects to the session. The connection object represents the client’s connection.
A [ConnectionCreatedEvent](./EventData.md#ConnectionCreatedEvent) object is passed into the event handler.

**connectionDestroyed** -- Sent when another client disconnects from the session. The connection object represents the connection that the client had to the session.
A [ConnectionDestroyedEvent](./EventData.md#ConnectionDestroyedEvent) object is passed into the event handler.

**error** (Object) — Sent if the attempt to connect to the session fails or if the connection to the session drops due to an error after a successful connection.
An [ErrorEvent](./EventData.md#ErrorEvent) object is passed into the event handler.

**otrnError** -- Sent if there is an error with the communication between the native session instance and the JS component.

**sessionConnected** -- Sent when the client connects to the session.
A [SessionConnectEvent](./EventData.md#SessionConnectEvent) object is passed into the event handler.

**sessionDisconnected** -- Sent when the client disconnects from the session.
A [SessionDisconnectEvent](./EventData.md#SessionDisconnectEvent) object is passed into the event handler.

**sessionReconnected** -- Sent when the local client has reconnected to the OpenTok session after its network connection was lost temporarily.

**sessionReconnecting** -- Sent when the local client has lost its connection to an OpenTok session and is trying to reconnect. This results from a loss in network connectivity. If the client can reconnect to the session, the `sessionReconnected` message is sent. Otherwise, if the client cannot reconnect, the `sessionDisconnected` message is sent.

**signal** -- Sent when a signal is received in the session.
A [SignalEvent](./EventData.md#SignalEvent) object is passed into the event handler.

**streamCreated** -- Sent when a new stream is created in this session.
A [StreamCreatedEvent](./EventData.md#StreamCreatedEvent) object is passed into the event handler.

**streamDestroyed** -- Sent when a stream is no longer published to the session.
A [StreamDestroyedEvent](./EventData.md#StreamDestroyedEvent) object is passed into the event handler.

**streamPropertyChanged** -- Sent when a stream has started or stopped publishing audio or video or if the video dimensions of the stream have changed. A [StreamPropertyChangedEvent](./EventData.md#StreamPropertyChangedEvent) object
is passed into the event handler.
