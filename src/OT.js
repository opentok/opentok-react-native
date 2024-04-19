import { NativeModules, NativeEventEmitter, PermissionsAndroid } from 'react-native';
import { each } from 'underscore';

const OT = NativeModules.OTSessionManager;
const nativeEvents = new NativeEventEmitter(OT);

const checkAndroidPermissions = (audioTrack, videoTrack, isScreenSharing) => new Promise((resolve, reject) => {
  const permissionsToCheck = [
    ... audioTrack ? [PermissionsAndroid.PERMISSIONS.RECORD_AUDIO] : [],
    ... (videoTrack && !isScreenSharing) ? [PermissionsAndroid.PERMISSIONS.CAMERA] : [],
  ];
  PermissionsAndroid.requestMultiple(permissionsToCheck)
    .then((result) => {
      const permissionsError = {};
      permissionsError.permissionsDenied = [];
      each(result, (permissionValue, permissionType) => {
        // Check if the permission is denied or set to 'never_ask_again'.
        if (permissionValue === 'denied' || permissionValue === 'never_ask_again' ) {
          permissionsError.permissionsDenied.push(permissionType);
          permissionsError.type = 'Permissions error';
        }
      });
      if (permissionsError.permissionsDenied.length > 0) {
        reject(permissionsError);
      } else {
        resolve();
      }
    })
    .catch((error) => {
      reject(error);
    });
});

const setNativeEvents = (events) => {
  const eventNames = Object.keys(events);
  OT.setNativeEvents(eventNames);
  
  let hasRegisteredEvents;
  if (nativeEvents.listeners) {
    const allEvents = nativeEvents.listeners();
    hasRegisteredEvents = (eventType) => allEvents.includes(eventType);
  } else {
    hasRegisteredEvents = (eventType) => nativeEvents.listenerCount(eventType) > 0;
  }

  each(events, (eventHandler, eventType) => {
    if (!hasRegisteredEvents(eventType)) {
      nativeEvents.addListener(eventType, eventHandler);
    }
  });
};

const removeNativeEvents = (events) => {
  const eventNames = Object.keys(events);
  OT.removeNativeEvents(eventNames);
  each(events, (_eventHandler, eventType) => {
    nativeEvents.removeAllListeners(eventType);
  });
};

export {
  OT,
  nativeEvents,
  checkAndroidPermissions,
  setNativeEvents,
  removeNativeEvents,
};
