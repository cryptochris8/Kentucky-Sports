import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    include: ['src/**/*.test.ts'],
    environment: 'node',
  },
  resolve: {
    alias: {
      '@bluegrass/shared-models': path.resolve(__dirname, '../packages/shared_models/src'),
    },
  },
});
