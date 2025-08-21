import { PermissionsAndroid } from 'react-native';
import { each } from 'underscore';

import OpentokReactNative from './NativeOpentok';
const nativeEvents = {}; // To do. Impliment callbacks from native.
const OT = OpentokReactNative;

// Used by OTPublisher:
const checkAndroidPermissions = (audioTrack, videoTrack, isScreenSharing) =>
  new Promise((resolve, reject) => {
    const permissionsToCheck = [
      ...(audioTrack ? [PermissionsAndroid.PERMISSIONS.RECORD_AUDIO] : []),
      ...(videoTrack && !isScreenSharing
        ? [PermissionsAndroid.PERMISSIONS.CAMERA]
        : []),
    ];
    PermissionsAndroid.requestMultiple(permissionsToCheck)
      .then((result) => {
        const permissionsError = {};
        permissionsError.permissionsDenied = [];
        each(result, (permissionValue, permissionType) => {
          // Check if the permission is denied or set to 'never_ask_again'.
          if (
            permissionValue === 'denied' ||
            permissionValue === 'never_ask_again'
          ) {
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

export { OT, nativeEvents, checkAndroidPermissions };
