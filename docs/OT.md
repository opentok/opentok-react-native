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
