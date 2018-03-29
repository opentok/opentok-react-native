import { NativeModules, NativeEventEmitter, PermissionsAndroid } from 'react-native';
import { each } from 'underscore';

const OT = NativeModules.OTSessionManager;
const nativeEvents = new NativeEventEmitter(OT);

const checkAndroidPermissions = () => new Promise((resolve, reject) => {
  PermissionsAndroid.requestMultiple([
    PermissionsAndroid.PERMISSIONS.CAMERA,
    PermissionsAndroid.PERMISSIONS.RECORD_AUDIO])
    .then((result) => {
      const permissionsError = {};
      permissionsError.permissionsDenied = [];
      each(result, (permissionValue, permissionType) => {
        if (permissionValue === 'denied') {
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
  each(events, (eventHandler, eventType) => {
    const allEvents = nativeEvents.listeners();
    if (!allEvents.includes(eventType)) {
      nativeEvents.addListener(eventType, eventHandler);
    }
  });
};

const removeNativeEvents = (events) => {
  const eventNames = Object.keys(events);
  OT.removeNativeEvents(eventNames);
  each(events, (eventHandler, eventType) => {
    nativeEvents.removeListener(eventType, eventHandler);
  });
};

export {
  OT,
  nativeEvents,
  checkAndroidPermissions,
  setNativeEvents,
  removeNativeEvents,
};
