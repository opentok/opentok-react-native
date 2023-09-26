# OT

This library uses React Native bridging to expose native (iOS & Android) methods via a native module.
`OT` is a custom native module that includes methods for logging.

Please keep in mind that `OT` is not the same as `OT` in the JS SDK, the `OT` in this library refers to the iOS and Android `OTSessionManager` class.


## To enable logs:

By default, the native logs are disabled. Please using the following method to enable native logs.
```javascript
  OT.enableLogs(true);
```

## To disable logs:

```javascript
  OT.enableLogs(false);
```

## To get supported codecs for the client device

```javascript
  const supportedCodecs = await OT.getSupportedCodecs();
  console.log(supportedCodecs);
```

The `OT.getSupportedCodecs()` method returns a promise that resolves with an object defining the supported codecs on the device. This object includes two properties:

* `videoDecoderCodecs` -- An array of values, defining the video codecs for decoding that are supported on the device. Supported values are "VP8" and "H.264".

* `videoEncoderCodecs` -- An array of values, defining the video codecs for encoding that are supported on the device.. Supported values are "VP8" and "H.264".

See the OpenTok [video codecs](https://tokbox.com/developer/guides/codecs/) documentattion.
