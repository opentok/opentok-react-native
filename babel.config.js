module.exports = function (api) {
  const isTest = api.env('test');

  // For plugin tests, use a simpler preset that doesn't require React Native
  if (isTest && process.env.npm_lifecycle_event === 'test:plugin') {
    return {
      presets: [
        ['@babel/preset-env', { targets: { node: 'current' } }],
        '@babel/preset-typescript',
      ],
    };
  }

  // For main tests, use React Native preset
  if (isTest) {
    return {
      presets: ['module:@react-native/babel-preset'],
    };
  }

  return {
    overrides: [
      {
        exclude: /\/node_modules\//,
        presets: ['module:react-native-builder-bob/babel-preset'],
      },
      {
        include: /\/node_modules\//,
        presets: ['module:@react-native/babel-preset'],
      },
    ],
  };
};
