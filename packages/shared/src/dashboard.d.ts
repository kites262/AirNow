export interface DashboardRequest {
  latitude: number;
  longitude: number;
}

export interface DashboardLocation {
  city: string;
  district: string;
  detail?: string;
  latitude: number;
  longitude: number;
  coordType: 'wgs84';
}

export interface AirPollutants {
  pm25: number;
  pm10: number;
  so2: number;
  no2: number;
  o3: number;
  co: number;
}

export interface AirInfo {
  aqi: number;
  levelText: string;
  advice: string;
  pollutants: AirPollutants;
  unit: {
    pm: string;
    co: string;
  };
  updateTime: string;
}

export type AirMetricCode = 'aqi' | keyof AirPollutants;

export type AirHourlyPollutants = {
  [K in keyof AirPollutants]: number | null;
};

export interface AirHourlyForecastHour {
  forecastTime: string;
  aqi: number;
  pollutants: AirHourlyPollutants;
}

export interface DashboardAirHourlyForecast {
  hours: AirHourlyForecastHour[];
  unit: {
    aqi: 'AQI';
    pm: string;
    co: string;
  };
}

export interface ForecastDay {
  date: string;
  tempMax: number;
  tempMin: number;
  humidity: number;
}

export interface ForecastSeries {
  name: string;
  type: 'line';
  data: number[];
}

export interface DashboardForecast {
  days: ForecastDay[];
  series: ForecastSeries[];
}

export type WeatherProviderName = 'mock' | (string & {});

export interface DashboardSnapshotMeta {
  provider: WeatherProviderName;
  ttlSeconds: number;
  fetchedAt: string;
}

export interface DashboardSnapshot {
  location: DashboardLocation;
  air: AirInfo;
  airHourlyForecast: DashboardAirHourlyForecast;
  forecast: DashboardForecast;
  meta: DashboardSnapshotMeta;
}

export interface DashboardResponse extends Omit<DashboardSnapshot, 'meta'> {
  meta: DashboardSnapshotMeta & {
    cached: boolean;
  };
}
