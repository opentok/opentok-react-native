import { NativeModules, NativeEventEmitter, PermissionsAndroid } from 'react-native';

const _ = require('underscore');

const OT = NativeModules.OTSessionManager;
const nativeEvents = new NativeEventEmitter(OT);

const createSession = data => new Promise((resolve, reject) => {
  OT.initSession(data.apiKey, data.sessionId);
  OT.connect(data.token, (error) => {
    if (error) {
      reject(error);
    } else {
      resolve();
    }
  });
});

const checkAndroidPermissions = () => new Promise((resolve, reject) => {
  PermissionsAndroid.requestMultiple([
    PermissionsAndroid.PERMISSIONS.CAMERA,
    PermissionsAndroid.PERMISSIONS.RECORD_AUDIO])
    .then((result) => {
      const permissionsError = {};
      permissionsError.permissionsDenied = [];
      _.each(result, (permissionValue, permissionType) => {
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

const createPublisher = properties => new Promise((resolve, reject) => {
  OT.initPublisher(properties, (initPublisherError) => {
    if (initPublisherError) {
      reject(initPublisherError);
    } else {
      OT.publish((publishError) => {
        if (publishError) {
          reject(publishError);
        } else {
          resolve();
        }
      });
    }
  });
});

const disconnectSession = () => new Promise((resolve, reject) => {
  OT.disconnectSession((disconnectError) => {
    if (disconnectError) {
      reject(disconnectError);
    } else {
      resolve();
    }
  });
});

const setNativeEvents = (events) => {
  const eventNames = Object.keys(events);
  OT.setNativeEvents(eventNames);
  _.each(events, (eventHandler, eventType) => {
    const allEvents = nativeEvents.listeners();
    if (!allEvents.includes(eventType)) {
      nativeEvents.addListener(eventType, eventHandler);
    }
  });
};

const removeNativeEvents = (events) => {
  const eventNames = Object.keys(events);
  OT.removeNativeEvents(eventNames);
  _.each(events, (eventHandler, eventType) => {
    nativeEvents.removeListener(eventType, eventHandler);
  });
};

export {
  createSession,
  createPublisher,
  OT,
  nativeEvents,
  disconnectSession,
  checkAndroidPermissions,
  setNativeEvents,
  removeNativeEvents,
};
