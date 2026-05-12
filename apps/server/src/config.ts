import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { loadEnvFile } from 'node:process';

import type { WeatherProviderName } from '@airnow/shared';

type EnvSource = Record<string, string | undefined>;

export type Config = {
  port: number;
  apiPrefix: string;
  weatherProvider: WeatherProviderName;
  qweatherHost: string;
  qweatherToken: string;
};

function loadServerEnv() {
  const envPath = join(process.cwd(), '.env');

  if (existsSync(envPath)) {
    loadEnvFile(envPath);
  }
}

function parseNumber(value: string | undefined, fallback: number) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function normalizeApiPrefix(value: string | undefined) {
  if (!value || value === '/') {
    return '';
  }

  const trimmed = value.trim().replace(/^\/+|\/+$/g, '');
  return trimmed ? `/${trimmed}` : '';
}

export function createConfig(env: EnvSource): Config {
  return {
    port: parseNumber(env.PORT, 3000),
    apiPrefix: normalizeApiPrefix(env.API_PREFIX ?? '/api'),
    weatherProvider: (env.WEATHER_PROVIDER ?? 'mock') as WeatherProviderName,
    qweatherHost: env.QWEATHER_HOST ?? 'https://devapi.qweather.com',
    qweatherToken: env.QWEATHER_TOKEN ?? '',
  };
}

loadServerEnv();

export const config = createConfig(process.env);
