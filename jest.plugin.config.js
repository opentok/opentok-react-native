module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  testMatch: ["**/plugin/__tests__/**/*.test.ts"],
  moduleFileExtensions: ["ts", "tsx", "js", "jsx"],
  transform: {
    "^.+\\.tsx?$": [
      "ts-jest",
      {
        tsconfig: {
          jsx: "react",
          esModuleInterop: true,
          allowSyntheticDefaultImports: true,
          module: "commonjs",
          moduleResolution: "node",
          strict: false,
          skipLibCheck: true,
          verbatimModuleSyntax: false,
        },
      },
    ],
  },
  modulePathIgnorePatterns: ["<rootDir>/example/", "<rootDir>/lib/"],
};
