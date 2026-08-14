import globals from 'globals';

export default [
  {
    files: ['**/*.js'],
    ignores: ['node_modules/**'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: globals.node,
    },
    rules: {
      'no-unused-vars': ['error', {argsIgnorePattern: '^_'}],
      'no-undef': 'error',
    },
  },
];
