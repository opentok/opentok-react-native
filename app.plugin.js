/**
 * Expo config plugin entry point for opentok-react-native.
 *
 * This file serves as the main entry point for the Expo config plugin system.
 * It loads the compiled TypeScript plugin code from the plugin/build directory.
 *
 * The plugin automatically configures iOS and Android permissions required for
 * video calling with the OpenTok/Vonage Video API.
 *
 * @see https://docs.expo.dev/config-plugins/introduction/
 */

module.exports = require("./plugin/build/index");
