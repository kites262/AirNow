import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

import { createConfig } from './config';

const config = createConfig(process.env as Record<string, string | undefined>);

export default defineConfig({
  plugins: [vue()],
  server: {
    host: config.devHost,
    port: config.devPort,
    proxy: {
      [config.apiBase]: {
        target: config.proxyTarget,
        changeOrigin: true,
      },
    },
  },
  preview: {
    host: config.previewHost,
    port: config.previewPort,
  },
});
