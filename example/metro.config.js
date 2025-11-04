const path = require('path');
const { getDefaultConfig } = require('@react-native/metro-config');

module.exports = {
  ...getDefaultConfig(__dirname),
  watchFolders: [path.resolve(__dirname, '..')],
  resolver: {
    nodeModulesPaths: [
      path.resolve(__dirname, 'node_modules'),
      path.resolve(__dirname, '../node_modules'),
    ],
  },
};
