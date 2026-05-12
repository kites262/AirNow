import type {
  AirHourlyForecastHour,
  AirInfo,
  AirMetricCode,
  AirPollutants,
  DashboardAirHourlyForecast,
  DashboardForecast,
  DashboardLocation,
  DashboardRequest,
  DashboardResponse,
  DashboardSnapshot,
  DashboardSnapshotMeta,
  ForecastDay,
  ForecastSeries,
  WeatherProviderName,
} from '@airnow/shared';

export type {
  AirHourlyForecastHour,
  AirInfo,
  AirMetricCode,
  AirPollutants,
  DashboardAirHourlyForecast,
  DashboardForecast,
  DashboardLocation,
  DashboardRequest,
  DashboardResponse,
  DashboardSnapshot,
  DashboardSnapshotMeta,
  ForecastDay,
  ForecastSeries,
  WeatherProviderName,
};

export type DashboardWeatherProvider = {
  createDashboardSnapshot(request: DashboardRequest): Promise<DashboardSnapshot>;
};
