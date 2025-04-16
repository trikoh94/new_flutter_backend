module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  parser: "@babel/eslint-parser",
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
    requireConfigFile: false,
  },
  extends: [
    "eslint:recommended",
  ],
  rules: {
    "indent": "off",
    "quotes": "off",
    "comma-dangle": "off",
    "object-curly-spacing": "off",
    "max-len": "off",
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
