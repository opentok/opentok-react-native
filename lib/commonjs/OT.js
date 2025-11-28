"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.nativeEvents = exports.checkAndroidPermissions = exports.OT = void 0;
var _reactNative = require("react-native");
var _underscore = require("underscore");
var _NativeOpentok = _interopRequireDefault(require("./NativeOpentok.js"));
function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
const nativeEvents = exports.nativeEvents = {}; // To do. Impliment callbacks from native.
const OT = exports.OT = _NativeOpentok.default;

// Used by OTPublisher:
const checkAndroidPermissions = (audioTrack, videoTrack, isScreenSharing) => new Promise((resolve, reject) => {
  const permissionsToCheck = [...(audioTrack ? [_reactNative.PermissionsAndroid.PERMISSIONS.RECORD_AUDIO] : []), ...(videoTrack && !isScreenSharing ? [_reactNative.PermissionsAndroid.PERMISSIONS.CAMERA] : [])];
  _reactNative.PermissionsAndroid.requestMultiple(permissionsToCheck).then(result => {
    const permissionsError = {};
    permissionsError.permissionsDenied = [];
    (0, _underscore.each)(result, (permissionValue, permissionType) => {
      // Check if the permission is denied or set to 'never_ask_again'.
      if (permissionValue === 'denied' || permissionValue === 'never_ask_again') {
        permissionsError.permissionsDenied.push(permissionType);
        permissionsError.type = 'Permissions error';
      }
    });
    if (permissionsError.permissionsDenied.length > 0) {
      reject(permissionsError);
    } else {
      resolve();
    }
  }).catch(error => {
    reject(error);
  });
});
exports.checkAndroidPermissions = checkAndroidPermissions;
//# sourceMappingURL=OT.js.map