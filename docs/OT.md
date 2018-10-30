### OT

This library uses React Native bridging to expose native (iOS & Android) methods via a native module. We've create a custom native module, `OT`, for this library.

Below, you will find a list of methods that you can access at any time to configure logs, etc:

### To enable logs:
By default, the native logs are disabled. Please using the following method to enable native logs.
```javascript
  OT.enableLogs(true);
```

### To disable logs:
```javascript
  OT.enableLogs(false);
```
