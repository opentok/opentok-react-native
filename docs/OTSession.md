### OTSession Component

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| apiKey | String | Yes | TokBox API Key
| sessionId | String | Yes | TokBox Session ID
| token | String | Yes | TokBox token
| options | Object | No | Used to define session options
| signal | Object | No | Used to send a signal to the session
| eventHandlers | Object&lt;Function&gt; | No | Event handlers passed into the native session instance.

The `OTSession` component manages the connection to an OpenTok Session. It passes the sessionId to the `sessionId` prop to its child components. To disconnect the session, unmount the `OTSession` component. To publish and subscribe, you must nest `OTPublisher` and `OTSubscriber` inside `OTSession`:
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
    const { isConnected } = this.state;
    if (isConnected) {
      this.otSessionRef.current.signal({
        data: '',
        to: '', // optional - connectionId of connected client you want to send the signal to
        type: '', // optional
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

## Events 
  * **archiveStarted** (Object) — Sent when an archive recording of a session starts. If you connect to a session in which recording is already in progress, this message is sent when you connect.

  * **archiveStopped** (String) — Sent when an archive recording of a session stops.

  * **connectionCreated** (Object) — Sent when another client connects to the session. The connection object represents the client’s connection.

  * **connectionDestroyed** (Object) - Sent when another client disconnects from the session. The connection object represents the connection that the client had to the session.
  
  * **error** (Object) — Sent if the attempt to connect to the session fails or if the connection to the session drops due to an error after a successful connection.

  * **otrnError** (Object) — Sent if there is an error with the communication between the native session instance and the JS component.

  * **sessionConnected** () - Sent when the client connects to the session.
  
  * **sessionDisconnected** () — Sent when the client disconnects from the session.

  * **sessionReconnected** () - Sent when the local client has reconnected to the OpenTok session after its network connection was lost temporarily.

  * **sessionReconnecting** () — Sent when the local client has lost its connection to an OpenTok session and is trying to reconnect. This results from a loss in network connectivity. If the client can reconnect to the session, the `sessionReconnected` message is sent. Otherwise, if the client cannot reconnect, the `sessionDisconnected` message is sent.

  * **signal** (Object) - Sent when a message is received in the session.
  
  * **streamCreated** (Object) — Sent when a new stream is created in this session.

  * **streamDestroyed** (Object) - Sent when a stream is no longer published to the session.
  
  * **streamPropertyChanged** (Object) - Sent when a stream has started or stopped publishing audio or video or if the video dimensions of the stream have changed.

  ### Setting Session options:

  You can set the session options using the `options` prop. Please note that all session options are optional:
```javascript
class App extends Component {
  constructor(props) {
    super(props);
    this.sessionOptions = {
      connectionEventsSuppressed: true, // default is false
      androidZOrder: '', // Android only - valid options are 'mediaOverlay' or 'onTop'
      androidOnTop: '',  // Android only - valid options are 'publisher' or 'subscriber'
      useTextureViews: true,  // Android only - default is false
      isCamera2Capable: false, // Android only - default is false
      ipWhitelist: false, // https://tokbox.com/developer/sdks/js/reference/OT.html#initSession - ipWhitelist
      enableStereoOutput: true // Enable stereo output, default is false
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