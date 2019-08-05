## Event Data

Below, you will find the strucutre of the event objects broken down by event type.

### Archive Event

You can find the structure of the object below: 

```javascript
  archive = {
    archiveId: '',
    name: '',
    sessionId: '',
  };
```

### Audio Network Stats

You can find the structure of the object below:

```javascript
  audioNetworkStats = {
    audioPacketsLost: '',
    audioBytesReceived: '',
    audioPacketsReceived: '',
  };
```

### Connection Event

You can find the structure of the object below: 

```javascript
  connection = {
    connectionId: '',
    creationTime: '',
    data: '',
  };
```

### Error Event
You can find the structure of the object below: 

```javascript
  error = {
    code: '',
    message: '',
  };
```

### Stream Event

You can find the structure of the object below: 

```javascript
  stream = {
    streamId: '',
    name: '',
    connectionId: '', // This will be removed after v0.11.0 because it's exposed via the connection object
    connection: {
      connectionId: '',
      creationTime: '',
      data: '',
    },
    hasAudio: '',
    hasVideo: '',
    sessionId: '',
    creationTime: '',
    height: '',
    width: '',
    videoType: '', // camera or screen
  };
```

### Stream Property Changed event

```javascript
  event = {
    stream = {
      streamId: '',
      name: '',
      connectionId: '', // This will be removed after v0.11.0 because it's exposed via the connection object
      connection: {
        connectionId: '',
        creationTime: '',
        data: '',
     },
      hasAudio: '',
      hasVideo: '',
      sessionId: '',
      creationTime: '',
      height: '',
      width: '',
      videoType: '', // camera or screen
     },
    oldValue: '',
    newValue: '',
    changedProperty: '',
  };
```

### Video Network Stats
You can find the structure of the object below:

```javascript
  videoNetworkStats = {
    videoPacketsLost: '',
    videoBytesReceived: '',
    videoPacketsReceived: '',
  };
```