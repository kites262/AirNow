import { Injectable, Logger, BadGatewayException } from '@nestjs/common';
import axios, { isAxiosError } from 'axios';
import type {
  AirHourlyForecastHour,
  DashboardRequest,
  DashboardSnapshot,
  ForecastDay,
} from '@airnow/shared';

import type { DashboardWeatherProvider } from './dashboard.types';
import { NominatimService } from './nominatim.service';
import { config } from '../../config';
import { resolveLocationFromCoordinates } from './location-resolver';

type QWeatherAirIndex = {
  code?: string;
  name?: string;
  aqi?: number | string;
  aqiDisplay?: string;
  level?: string | null;
  category?: string | null;
  color?: { red: number; green: number; blue: number; alpha: number };
  primaryPollutant?: { code: string; name: string; fullName: string } | null;
  health: {
    effect?: string | null;
    advice: {
      generalPopulation?: string | null;
      sensitivePopulation?: string | null;
    } | null;
  } | null;
};

type QWeatherAirPollutant = {
  code?: string;
  name?: string;
  fullName?: string;
  concentration?: { value?: number | string; unit?: string };
  subIndexes?: { code?: string; aqi?: number | string; aqiDisplay?: string }[];
};

type QWeatherAirResponse = {
  code?: string;
  metadata?: { tag?: string };
  indexes?: QWeatherAirIndex[];
  pollutants?: QWeatherAirPollutant[];
  stations?: { id?: string; name?: string }[];
};

type QWeatherAirHourlyHour = {
  forecastTime?: string;
  indexes?: QWeatherAirIndex[];
  pollutants?: QWeatherAirPollutant[];
};

type QWeatherAirHourlyResponse = {
  code?: string;
  metadata?: { tag?: string };
  hours?: QWeatherAirHourlyHour[];
};

type QWeatherForecastDaily = {
  fxDate?: string;
  tempMax?: string;
  tempMin?: string;
  humidity?: string;
};

type QWeatherForecastResponse = {
  code?: string;
  updateTime?: string;
  daily?: QWeatherForecastDaily[];
};

type QWeatherGeoLocation = {
  id?: string;
  name?: string;
  lat?: string;
  lon?: string;
  adm2?: string;
  adm1?: string;
  country?: string;
  type?: string;
  rank?: string;
};

type QWeatherGeoResponse = {
  code?: string;
  location?: QWeatherGeoLocation[];
};

@Injectable()
export class QWeatherProviderService implements DashboardWeatherProvider {
  private readonly logger = new Logger(QWeatherProviderService.name);
  private readonly ttlSeconds = 300;

  constructor(private readonly nominatim: NominatimService) {}

  async createDashboardSnapshot(request: DashboardRequest): Promise<DashboardSnapshot> {
    const { latitude, longitude } = request;
    const now = new Date();
    const fallbackLocation = resolveLocationFromCoordinates(latitude, longitude);

    const [airResponse, airHourlyResponse, forecastResponse, geoLocation, nominatimResult] = await Promise.all([
      this.fetchAirQuality(latitude, longitude),
      this.fetchAirHourlyForecast(latitude, longitude),
      this.fetchWeatherForecast(latitude, longitude),
      this.fetchGeoLocation(latitude, longitude),
      this.nominatim.reverse(latitude, longitude),
    ]);
    const location = geoLocation ?? fallbackLocation;

    const airIndexes = airResponse.indexes ?? [];
    const index = this.selectPrimaryIndex(airIndexes);
    const pollutantMap = this.createPollutantMap(airResponse.pollutants ?? []);

    const pollutants = {
      pm25: this.getConcentration(pollutantMap, 'pm2p5'),
      pm10: this.getConcentration(pollutantMap, 'pm10'),
      so2: this.getConcentration(pollutantMap, 'so2'),
      no2: this.getConcentration(pollutantMap, 'no2'),
      o3: this.getConcentration(pollutantMap, 'o3'),
      co: this.getConcentration(pollutantMap, 'co'),
    };

    const days: ForecastDay[] = (forecastResponse.daily ?? [])
      .map((day) => this.toForecastDay(day))
      .filter((day): day is ForecastDay => day !== null);
    const airHourlyForecastHours: AirHourlyForecastHour[] = (airHourlyResponse.hours ?? [])
      .map((hour) => this.toAirHourlyForecastHour(hour))
      .filter((hour): hour is AirHourlyForecastHour => hour !== null);

    const pmUnit = this.normalizeUnit(pollutantMap.get('pm2p5')?.concentration?.unit, 'ug/m3');
    const coUnit = this.normalizeUnit(pollutantMap.get('co')?.concentration?.unit, 'mg/m3');
    const updateTime = forecastResponse.updateTime
      ? new Date(forecastResponse.updateTime).toISOString()
      : now.toISOString();

    return {
      location: {
        city: location.city,
        district: location.district,
        detail: nominatimResult?.detail,
        latitude,
        longitude,
        coordType: 'wgs84',
      },
      air: {
        aqi: this.toNumber(index?.aqi, 0),
        levelText: index?.category ?? '',
        advice: index?.health?.advice?.generalPopulation ?? '',
        pollutants,
        unit: {
          pm: pmUnit,
          co: coUnit,
        },
        updateTime,
      },
      airHourlyForecast: {
        hours: airHourlyForecastHours,
        unit: {
          aqi: 'AQI',
          pm: this.resolveHourlyUnit(airHourlyForecastHours.length > 0 ? airHourlyResponse.hours ?? [] : [], 'pm2p5', pmUnit),
          co: this.resolveHourlyUnit(airHourlyForecastHours.length > 0 ? airHourlyResponse.hours ?? [] : [], 'co', coUnit),
        },
      },
      forecast: {
        days,
        series: [
          { name: '最高温', type: 'line', data: days.map((d) => d.tempMax) },
          { name: '最低温', type: 'line', data: days.map((d) => d.tempMin) },
          { name: '湿度', type: 'line', data: days.map((d) => d.humidity) },
        ],
      },
      meta: {
        provider: 'qweather',
        ttlSeconds: this.ttlSeconds,
        fetchedAt: now.toISOString(),
      },
    } satisfies DashboardSnapshot;
  }

  private async fetchAirHourlyForecast(lat: number, lon: number): Promise<QWeatherAirHourlyResponse> {
    const url = `${config.qweatherHost}/airquality/v1/hourly/${lat.toFixed(2)}/${lon.toFixed(2)}`;
    try {
      const { data } = await axios.get<QWeatherAirHourlyResponse>(url, {
        headers: { 'X-QW-Api-Key': config.qweatherToken },
      });

      if (!this.hasAirHourlyForecastPayload(data)) {
        this.logger.error(`QWeather hourly air API returned an unexpected payload: ${JSON.stringify(data)}`);
        throw new BadGatewayException('QWeather hourly air API returned an unexpected payload');
      }

      return data;
    } catch (error) {
      if (isAxiosError(error)) {
        this.logger.error(`QWeather hourly air API request failed: ${error.response?.status} ${error.message}`);
        throw new BadGatewayException(`QWeather hourly air API request failed: ${error.response?.status ?? error.message}`);
      }
      throw error;
    }
  }

  private async fetchAirQuality(lat: number, lon: number): Promise<QWeatherAirResponse> {
    const url = `${config.qweatherHost}/airquality/v1/current/${lat.toFixed(2)}/${lon.toFixed(2)}`;
    try {
      const { data } = await axios.get<QWeatherAirResponse>(url, {
        headers: { 'X-QW-Api-Key': config.qweatherToken },
      });

      if (!this.hasAirQualityPayload(data)) {
        this.logger.error(`QWeather air API returned an unexpected payload: ${JSON.stringify(data)}`);
        throw new BadGatewayException('QWeather air API returned an unexpected payload');
      }

      return data;
    } catch (error) {
      if (isAxiosError(error)) {
        this.logger.error(`QWeather air API request failed: ${error.response?.status} ${error.message}`);
        throw new BadGatewayException(`QWeather air API request failed: ${error.response?.status ?? error.message}`);
      }
      throw error;
    }
  }

  private async fetchWeatherForecast(lat: number, lon: number): Promise<QWeatherForecastResponse> {
    const location = `${lon.toFixed(2)},${lat.toFixed(2)}`;
    const url = `${config.qweatherHost}/v7/weather/7d`;
    try {
      const { data } = await axios.get<QWeatherForecastResponse>(url, {
        headers: { 'X-QW-Api-Key': config.qweatherToken },
        params: { location },
      });

      if (data.code !== '200' || !Array.isArray(data.daily)) {
        this.logger.error(`QWeather forecast API returned an unexpected payload: ${JSON.stringify(data)}`);
        throw new BadGatewayException(`QWeather forecast API returned code ${data.code ?? 'unknown'}`);
      }

      return data;
    } catch (error) {
      if (isAxiosError(error)) {
        this.logger.error(`QWeather forecast API request failed: ${error.response?.status} ${error.message}`);
        throw new BadGatewayException(`QWeather forecast API request failed: ${error.response?.status ?? error.message}`);
      }
      throw error;
    }
  }

  private async fetchGeoLocation(
    lat: number,
    lon: number,
  ): Promise<{ city: string; district: string } | null> {
    const location = `${lon.toFixed(2)},${lat.toFixed(2)}`;
    const url = `${config.qweatherHost}/geo/v2/city/lookup`;

    try {
      const { data } = await axios.get<QWeatherGeoResponse>(url, {
        headers: { 'X-QW-Api-Key': config.qweatherToken },
        params: {
          location,
          lang: 'zh',
          number: 20,
          range: 'cn',
        },
      });

      if (data.code !== '200' || !Array.isArray(data.location)) {
        this.logger.warn(`QWeather geo API returned an unexpected payload: ${JSON.stringify(data)}`);
        return null;
      }

      const matched = this.selectGeoLocation(data.location, lat, lon);
      if (!matched) {
        return null;
      }

      return {
        city: this.resolveCityName(matched),
        district: this.resolveDistrictName(matched),
      };
    } catch (error) {
      if (isAxiosError(error)) {
        this.logger.warn(`QWeather geo API request failed: ${error.response?.status} ${error.message}`);
        return null;
      }
      throw error;
    }
  }

  private getConcentration(map: Map<string, QWeatherAirPollutant>, code: string): number {
    return this.toNumber(map.get(code)?.concentration?.value, 0);
  }

  private getOptionalConcentration(map: Map<string, QWeatherAirPollutant>, code: string): number | null {
    const value = map.get(code)?.concentration?.value;

    if (value === undefined || value === null || value === '') {
      return null;
    }

    return this.toNumber(value, 0);
  }

  private createPollutantMap(pollutants: QWeatherAirPollutant[]) {
    return new Map(
      pollutants
        .filter((pollutant): pollutant is QWeatherAirPollutant & { code: string } => Boolean(pollutant.code))
        .map((pollutant) => [pollutant.code, pollutant]),
    );
  }

  private hasAirQualityPayload(data: QWeatherAirResponse | undefined): data is QWeatherAirResponse {
    return Boolean(
      data
      && Array.isArray(data.indexes)
      && Array.isArray(data.pollutants),
    );
  }

  private hasAirHourlyForecastPayload(
    data: QWeatherAirHourlyResponse | undefined,
  ): data is QWeatherAirHourlyResponse & { hours: QWeatherAirHourlyHour[] } {
    return Boolean(data && Array.isArray(data.hours));
  }

  private selectPrimaryIndex(indexes: QWeatherAirIndex[]): QWeatherAirIndex | undefined {
    const preferredCodes = new Set(['qaqi', 'cn-mee']);

    return indexes.find((index) => index.code ? preferredCodes.has(index.code) : false)
      ?? indexes.find((index) => Number.isFinite(this.toNumber(index.aqi, Number.NaN)))
      ?? indexes[0];
  }

  private toForecastDay(day: QWeatherForecastDaily): ForecastDay | null {
    if (!day.fxDate) {
      return null;
    }

    return {
      date: day.fxDate,
      tempMax: this.toNumber(day.tempMax, 0),
      tempMin: this.toNumber(day.tempMin, 0),
      humidity: this.toNumber(day.humidity, 0),
    };
  }

  private toAirHourlyForecastHour(hour: QWeatherAirHourlyHour): AirHourlyForecastHour | null {
    if (!hour.forecastTime) {
      return null;
    }

    const pollutantMap = this.createPollutantMap(hour.pollutants ?? []);
    const index = this.selectPrimaryIndex(hour.indexes ?? []);

    return {
      forecastTime: new Date(hour.forecastTime).toISOString(),
      aqi: this.toNumber(index?.aqi, 0),
      pollutants: {
        pm25: this.getOptionalConcentration(pollutantMap, 'pm2p5'),
        pm10: this.getOptionalConcentration(pollutantMap, 'pm10'),
        so2: this.getOptionalConcentration(pollutantMap, 'so2'),
        no2: this.getOptionalConcentration(pollutantMap, 'no2'),
        o3: this.getOptionalConcentration(pollutantMap, 'o3'),
        co: this.getOptionalConcentration(pollutantMap, 'co'),
      },
    };
  }

  private toNumber(value: number | string | undefined, fallback: number): number {
    const parsed = typeof value === 'number' ? value : Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  private resolveHourlyUnit(
    hours: QWeatherAirHourlyHour[],
    pollutantCode: string,
    fallback: string,
  ): string {
    for (const hour of hours) {
      const pollutant = this.createPollutantMap(hour.pollutants ?? []).get(pollutantCode);
      if (pollutant?.concentration?.unit) {
        return this.normalizeUnit(pollutant.concentration.unit, fallback);
      }
    }

    return fallback;
  }

  private normalizeUnit(unit: string | undefined, fallback: string): string {
    if (!unit) {
      return fallback;
    }

    return unit
      .replaceAll('μ', 'u')
      .replaceAll('µ', 'u')
      .replaceAll('³', '3');
  }

  private selectGeoLocation(
    locations: QWeatherGeoLocation[],
    lat: number,
    lon: number,
  ): QWeatherGeoLocation | null {
    const candidates = locations.filter((location) => {
      const candidateLat = this.toNumber(location.lat, Number.NaN);
      const candidateLon = this.toNumber(location.lon, Number.NaN);
      return Number.isFinite(candidateLat) && Number.isFinite(candidateLon);
    });

    if (candidates.length === 0) {
      return locations[0] ?? null;
    }

    return candidates.reduce((best, current) => {
      const currentDistance = this.distanceSquared(
        lat,
        lon,
        this.toNumber(current.lat, lat),
        this.toNumber(current.lon, lon),
      );
      const bestDistance = this.distanceSquared(
        lat,
        lon,
        this.toNumber(best.lat, lat),
        this.toNumber(best.lon, lon),
      );

      return currentDistance < bestDistance ? current : best;
    });
  }

  private resolveCityName(location: QWeatherGeoLocation): string {
    return location.adm2
      ?? location.adm1
      ?? location.name
      ?? '';
  }

  private resolveDistrictName(location: QWeatherGeoLocation): string {
    if (location.name && location.name !== location.adm2 && location.name !== location.adm1) {
      return location.name;
    }

    return location.adm1
      ?? location.adm2
      ?? location.name
      ?? '';
  }

  private distanceSquared(latA: number, lonA: number, latB: number, lonB: number) {
    return (latA - latB) ** 2 + (lonA - lonB) ** 2;
  }
}
