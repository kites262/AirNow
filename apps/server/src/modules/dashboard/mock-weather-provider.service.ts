import { Injectable } from '@nestjs/common';
import type {
  AirHourlyForecastHour,
  DashboardRequest,
  DashboardSnapshot,
  ForecastDay,
  WeatherProviderName,
} from '@airnow/shared';

import { config } from '../../config';
import type { DashboardWeatherProvider } from './dashboard.types';
import { NominatimService } from './nominatim.service';
import { resolveLocationFromCoordinates } from './location-resolver';

@Injectable()
export class MockWeatherProviderService implements DashboardWeatherProvider {
  private readonly provider: WeatherProviderName = config.weatherProvider;
  private readonly ttlSeconds = 120;
  private readonly defaultForecastDays = 6;

  constructor(private readonly nominatim: NominatimService) {}

  async createDashboardSnapshot(request: DashboardRequest): Promise<DashboardSnapshot> {
    const now = new Date();
    const location = resolveLocationFromCoordinates(request.latitude, request.longitude);
    const nominatimResult = await this.nominatim.reverse(request.latitude, request.longitude);
    const seed = this.createSeed(request.latitude, request.longitude);
    const forecastDays = this.buildForecast(now, this.defaultForecastDays, seed);
    const airHourlyForecastHours = this.buildAirHourlyForecast(now, 24, seed);
    const aqi = this.clamp(35 + (seed % 85) + Math.round((forecastDays[0]?.humidity ?? 50) / 6), 28, 180);
    const pollutants = {
      pm25: Math.round(aqi * 0.46),
      pm10: Math.round(aqi * 0.85),
      so2: Math.round(4 + aqi / 24),
      no2: Math.round(12 + aqi / 7),
      o3: Math.round(55 + (seed % 50)),
      co: Number((0.3 + aqi / 210).toFixed(1)),
    };
    const { levelText, advice } = this.getAirLevel(aqi);

    return {
      location: {
        city: location.city,
        district: location.district,
        detail: nominatimResult?.detail,
        latitude: request.latitude,
        longitude: request.longitude,
        coordType: 'wgs84',
      },
      air: {
        aqi,
        levelText,
        advice,
        pollutants,
        unit: {
          pm: 'ug/m3',
          co: 'mg/m3',
        },
        updateTime: now.toISOString(),
      },
      airHourlyForecast: {
        hours: airHourlyForecastHours,
        unit: {
          aqi: 'AQI',
          pm: 'ug/m3',
          co: 'mg/m3',
        },
      },
      forecast: {
        days: forecastDays,
        series: [
          { name: '最高温', type: 'line', data: forecastDays.map((day) => day.tempMax) },
          { name: '最低温', type: 'line', data: forecastDays.map((day) => day.tempMin) },
          { name: '湿度', type: 'line', data: forecastDays.map((day) => day.humidity) },
        ],
      },
      meta: {
        provider: this.provider,
        ttlSeconds: this.ttlSeconds,
        fetchedAt: now.toISOString(),
      },
    } satisfies DashboardSnapshot;
  }

  private buildAirHourlyForecast(today: Date, totalHours: number, seed: number): AirHourlyForecastHour[] {
    const hourStart = new Date(today);
    hourStart.setUTCMinutes(0, 0, 0);
    const aqiBase = this.clamp(42 + (seed % 80), 30, 165);

    return Array.from({ length: totalHours }, (_, index) => {
      const phase = seed * 0.03 + index * 0.38;
      const aqi = this.clamp(
        Math.round(aqiBase + Math.sin(phase) * 12 + Math.cos(phase * 0.75) * 7),
        25,
        190,
      );
      const forecastTime = new Date(hourStart);
      forecastTime.setUTCHours(hourStart.getUTCHours() + index);

      return {
        forecastTime: forecastTime.toISOString(),
        aqi,
        pollutants: {
          pm25: Math.round(aqi * 0.44 + Math.sin(phase + 0.4) * 3),
          pm10: Math.round(aqi * 0.82 + Math.cos(phase + 0.7) * 5),
          so2: Math.round(4 + aqi / 24 + Math.sin(phase * 0.8)),
          no2: Math.round(12 + aqi / 7 + Math.cos(phase * 0.9) * 2),
          o3: Math.round(52 + (seed % 24) + Math.sin(phase * 0.7) * 8),
          co: Number((0.28 + aqi / 215 + Math.cos(phase * 0.6) * 0.05).toFixed(1)),
        },
      };
    });
  }

  private buildForecast(today: Date, totalDays: number, seed: number): ForecastDay[] {
    const tempBase = this.clamp(Math.round(15 + ((seed % 12) - 4)), 8, 30);
    const humidityBase = this.clamp(44 + (seed % 30), 35, 86);

    return Array.from({ length: totalDays }, (_, index) => {
      const phase = (seed % 10) * 0.25 + index * 0.75;
      const tempMax = this.clamp(Math.round(tempBase + 6 + Math.sin(phase) * 4), 10, 38);
      const tempMin = this.clamp(tempMax - 8 - (index % 3), -2, 29);
      const humidity = this.clamp(Math.round(humidityBase + Math.cos(phase) * 9), 30, 95);
      const date = new Date(today);
      date.setUTCDate(today.getUTCDate() + index);

      return {
        date: date.toISOString().slice(0, 10),
        tempMax,
        tempMin,
        humidity,
      };
    });
  }

  private getAirLevel(aqi: number) {
    if (aqi <= 50) {
      return {
        levelText: '优',
        advice: '空气质量很好，\n适合户外活动。',
      };
    }

    if (aqi <= 100) {
      return {
        levelText: '良',
        advice: '空气质量可以接受，\n敏感人群外出时建议留意变化。',
      };
    }

    if (aqi <= 150) {
      return {
        levelText: '轻度污染',
        advice: '建议减少长时间户外活动，\n外出可佩戴口罩。',
      };
    }

    return {
      levelText: '中度污染',
      advice: '建议减少外出并关注实时预警信息。',
    };
  }

  private createSeed(latitude: number, longitude: number) {
    return Math.abs(Math.round(latitude * 100 + longitude * 10));
  }

  private clamp(value: number, min: number, max: number) {
    return Math.min(Math.max(value, min), max);
  }
}
