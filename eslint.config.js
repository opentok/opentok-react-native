module.exports = {
  ignores: ['node_modules/', 'example/ios/Pods', 'lib/'],
  languageOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    parserOptions: {
      ecmaFeatures: {
        jsx: true,
      },
    },
  },
};
