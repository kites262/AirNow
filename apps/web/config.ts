type EnvSource = Record<string, string | undefined>;

export type Config = {
  apiBase: string;
  proxyTarget: string;
  devHost: string;
  devPort: number;
  previewHost: string;
  previewPort: number;
};

function parseNumber(value: string | undefined, fallback: number) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function normalizePathPrefix(value: string | undefined) {
  if (!value || value === '/') {
    return '';
  }

  const trimmed = value.trim().replace(/^\/+|\/+$/g, '');
  return trimmed ? `/${trimmed}` : '';
}

export function createConfig(env: EnvSource): Config {
  return {
    apiBase: normalizePathPrefix(env.VITE_API_BASE ?? '/api'),
    proxyTarget: env.VITE_PROXY_TARGET ?? 'http://localhost:3000',
    devHost: env.VITE_DEV_HOST ?? '0.0.0.0',
    devPort: parseNumber(env.VITE_DEV_PORT, 5173),
    previewHost: env.VITE_PREVIEW_HOST ?? '0.0.0.0',
    previewPort: parseNumber(env.VITE_PREVIEW_PORT, 4173),
  };
}
