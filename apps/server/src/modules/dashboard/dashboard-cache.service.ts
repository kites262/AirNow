import { Injectable } from '@nestjs/common';

import type { DashboardSnapshot } from './dashboard.types';

interface CacheEntry {
  expiresAt: number;
  value: DashboardSnapshot;
}

@Injectable()
export class DashboardCacheService {
  private readonly store = new Map<string, CacheEntry>();

  get(key: string): DashboardSnapshot | null {
    const item = this.store.get(key);

    if (!item) {
      return null;
    }

    if (Date.now() > item.expiresAt) {
      this.store.delete(key);
      return null;
    }

    return item.value;
  }

  set(key: string, value: DashboardSnapshot, ttlSeconds: number) {
    this.store.set(key, {
      value,
      expiresAt: Date.now() + ttlSeconds * 1000,
    });
  }
}
