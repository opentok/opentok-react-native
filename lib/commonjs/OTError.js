"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.handleSignalError = exports.handleError = void 0;
const handleError = error => {
  console.log('OTRN JS: There was an error: ', error);
};
exports.handleError = handleError;
const handleSignalError = error => {
  if (error) {
    console.log(`OTRN JS: There was an error sending the signal ${error}`);
  }
};
exports.handleSignalError = handleSignalError;
//# sourceMappingURL=OTError.js.map