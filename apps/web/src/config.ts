import { createConfig, type Config } from '../config';

export type { Config };

export const config = createConfig(import.meta.env as Record<string, string | undefined>);

