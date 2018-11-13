## Event Data

Below, you will find the strucutre of the event objects broken down by event type.

### Archive Event

You can find the structure of the object below: 

```javascript
  archive = {
    archiveId: '',
    name: '',
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
    connectionId: '',
    hasAudio: '',
    hasVideo: '',
    creationTime: '',
    height: '',
    width: '',
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