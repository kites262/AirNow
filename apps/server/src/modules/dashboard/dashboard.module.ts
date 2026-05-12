import { Module } from '@nestjs/common';

import { DashboardCacheService } from './dashboard-cache.service';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';
import { MockWeatherProviderService } from './mock-weather-provider.service';
import { NominatimService } from './nominatim.service';
import { QWeatherProviderService } from './qweather-provider.service';
import { WEATHER_PROVIDER } from './dashboard.tokens';
import { config } from '../../config';

@Module({
  controllers: [DashboardController],
  providers: [
    DashboardService,
    DashboardCacheService,
    NominatimService,
    MockWeatherProviderService,
    QWeatherProviderService,
    {
      provide: WEATHER_PROVIDER,
      useFactory: (nominatim: NominatimService) => {
        return config.weatherProvider === 'qweather'
          ? new QWeatherProviderService(nominatim)
          : new MockWeatherProviderService(nominatim);
      },
      inject: [NominatimService],
    },
  ],
})
export class DashboardModule {}
