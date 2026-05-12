import { Inject, Injectable } from '@nestjs/common';
import type { DashboardRequest, DashboardResponse } from '@airnow/shared';

import { DashboardCacheService } from './dashboard-cache.service';
import { NominatimService } from './nominatim.service';
import { WEATHER_PROVIDER } from './dashboard.tokens';
import type { DashboardWeatherProvider } from './dashboard.types';

@Injectable()
export class DashboardService {
  constructor(
    @Inject(DashboardCacheService)
    private readonly cacheService: DashboardCacheService,
    @Inject(WEATHER_PROVIDER)
    private readonly weatherProvider: DashboardWeatherProvider,
    private readonly nominatim: NominatimService,
  ) {}

  async getDashboard(request: DashboardRequest): Promise<DashboardResponse> {
    const cacheKey = this.getCacheKey(request);
    const cached = this.cacheService.get(cacheKey);

    if (cached) {
      const snapshot = { ...cached };

      if (!snapshot.location.detail) {
        const nominatimResult = await this.nominatim.reverse(request.latitude, request.longitude);
        if (nominatimResult) {
          snapshot.location = { ...snapshot.location, detail: nominatimResult.detail };
          this.cacheService.set(cacheKey, snapshot, snapshot.meta.ttlSeconds);
        }
      }

      return {
        ...snapshot,
        meta: {
          ...snapshot.meta,
          cached: true,
        },
      };
    }

    const snapshot = await this.weatherProvider.createDashboardSnapshot(request);
    this.cacheService.set(cacheKey, snapshot, snapshot.meta.ttlSeconds);

    return {
      ...snapshot,
      meta: {
        ...snapshot.meta,
        cached: false,
      },
    };
  }

  private getCacheKey(request: DashboardRequest) {
    return [
      request.latitude.toFixed(4),
      request.longitude.toFixed(4),
    ].join(':');
  }
}
