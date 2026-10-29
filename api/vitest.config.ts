import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['test/**/*.test.ts'],
    globalSetup: ['test/global-setup.ts'],
    // The API tests share one database, so test files run one after the other
    fileParallelism: false,
    testTimeout: 30_000,
    hookTimeout: 60_000,
  },
});
