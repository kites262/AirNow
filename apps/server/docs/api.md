# AirNow API 文档

## 基本信息

- Base URL（本地）：`http://localhost:3000/api`
- API 前缀：`/api`（可通过环境变量 `API_PREFIX` 覆盖）
- Content-Type：`application/json`
- 认证：无

## 通用说明

- 所有请求体都会进行校验，字段缺失或类型不正确会返回 400。
- 额外字段会被拒绝（`ValidationPipe` + `forbidNonWhitelisted`）。
- 所有时间字段均为 ISO 8601 字符串。

## GET `/health`

用于健康检查。

**响应示例**

```json
{
  "ok": true,
  "timestamp": "2026-04-10T12:00:00.000Z",
  "service": "airnow-api"
}
```

## POST `/dashboard`

获取仪表盘数据（空气质量 + 天气趋势）。

**请求体**

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `latitude` | number | 是 | 纬度（`-90` ~ `90`） |
| `longitude` | number | 是 | 经度（`-180` ~ `180`） |

**请求示例**

```json
{
  "latitude": 39.9042,
  "longitude": 116.4074
}
```

**响应体结构**

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `location` | object | 地点与坐标信息 |
| `location.city` | string | 城市 |
| `location.district` | string | 区/县 |
| `location.latitude` | number | 纬度 |
| `location.longitude` | number | 经度 |
| `location.coordType` | string | 坐标类型（固定为 `wgs84`） |
| `air` | object | 空气质量信息 |
| `air.aqi` | number | AQI 数值 |
| `air.levelText` | string | 等级描述 |
| `air.advice` | string | 健康建议 |
| `air.pollutants` | object | 污染物指标 |
| `air.pollutants.pm25` | number | PM2.5 |
| `air.pollutants.pm10` | number | PM10 |
| `air.pollutants.so2` | number | SO2 |
| `air.pollutants.no2` | number | NO2 |
| `air.pollutants.o3` | number | O3 |
| `air.pollutants.co` | number | CO |
| `air.unit` | object | 单位 |
| `air.unit.pm` | string | 颗粒物单位（示例：`ug/m3`） |
| `air.unit.co` | string | CO 单位（示例：`mg/m3`） |
| `air.updateTime` | string | 更新时间 |
| `airHourlyForecast` | object | 未来24小时逐小时空气质量预报 |
| `airHourlyForecast.hours` | array | 逐小时空气质量列表 |
| `airHourlyForecast.hours[].forecastTime` | string | 预报时间 |
| `airHourlyForecast.hours[].aqi` | number | AQI 数值 |
| `airHourlyForecast.hours[].pollutants` | object | 该小时污染物指标 |
| `airHourlyForecast.hours[].pollutants.pm25` | number \| null | PM2.5，若上游未返回则为 `null` |
| `airHourlyForecast.hours[].pollutants.pm10` | number \| null | PM10，若上游未返回则为 `null` |
| `airHourlyForecast.hours[].pollutants.so2` | number \| null | SO2，若上游未返回则为 `null` |
| `airHourlyForecast.hours[].pollutants.no2` | number \| null | NO2，若上游未返回则为 `null` |
| `airHourlyForecast.hours[].pollutants.o3` | number \| null | O3，若上游未返回则为 `null` |
| `airHourlyForecast.hours[].pollutants.co` | number \| null | CO，若上游未返回则为 `null` |
| `airHourlyForecast.unit` | object | 逐小时空气质量单位 |
| `airHourlyForecast.unit.aqi` | string | AQI 标签（固定为 `AQI`） |
| `airHourlyForecast.unit.pm` | string | 颗粒物单位（示例：`ug/m3`） |
| `airHourlyForecast.unit.co` | string | CO 单位（示例：`mg/m3`） |
| `forecast` | object | 未来天气趋势 |
| `forecast.days` | array | 天气日列表 |
| `forecast.days[].date` | string | 日期（`YYYY-MM-DD`） |
| `forecast.days[].tempMax` | number | 最高温度数值 |
| `forecast.days[].tempMin` | number | 最低温度数值 |
| `forecast.days[].humidity` | number | 湿度（0~100） |
| `forecast.series` | array | 折线图序列 |
| `forecast.series[].name` | string | 序列名称 |
| `forecast.series[].type` | string | 序列类型（固定为 `line`） |
| `forecast.series[].data` | number[] | 与 `days` 对齐的数值序列 |
| `meta` | object | 响应元信息 |
| `meta.provider` | string | Provider 名称 |
| `meta.ttlSeconds` | number | 缓存 TTL（秒） |
| `meta.fetchedAt` | string | 抓取时间 |
| `meta.cached` | boolean | 是否来自缓存 |

**响应示例**

```json
{
  "location": {
    "city": "北京",
    "district": "朝阳区",
    "latitude": 39.9042,
    "longitude": 116.4074,
    "coordType": "wgs84"
  },
  "air": {
    "aqi": 92,
    "levelText": "良",
    "advice": "空气质量可以接受，\n敏感人群外出时建议留意变化。",
    "pollutants": {
      "pm25": 42,
      "pm10": 78,
      "so2": 8,
      "no2": 25,
      "o3": 89,
      "co": 0.7
    },
    "unit": {
      "pm": "ug/m3",
      "co": "mg/m3"
    },
    "updateTime": "2026-04-10T12:00:00.000Z"
  },
  "airHourlyForecast": {
    "hours": [
      {
        "forecastTime": "2026-04-10T13:00:00.000Z",
        "aqi": 88,
        "pollutants": {
          "pm25": 40,
          "pm10": 74,
          "so2": 7,
          "no2": 24,
          "o3": 86,
          "co": 0.7
        }
      },
      {
        "forecastTime": "2026-04-10T14:00:00.000Z",
        "aqi": 91,
        "pollutants": {
          "pm25": 42,
          "pm10": 76,
          "so2": 8,
          "no2": 25,
          "o3": 89,
          "co": 0.7
        }
      }
    ],
    "unit": {
      "aqi": "AQI",
      "pm": "ug/m3",
      "co": "mg/m3"
    }
  },
  "forecast": {
    "days": [
      { "date": "2026-04-10", "tempMax": 26, "tempMin": 15, "humidity": 62 },
      { "date": "2026-04-11", "tempMax": 25, "tempMin": 14, "humidity": 60 }
    ],
    "series": [
      { "name": "最高温", "type": "line", "data": [26, 25] },
      { "name": "最低温", "type": "line", "data": [15, 14] },
      { "name": "湿度", "type": "line", "data": [62, 60] }
    ]
  },
  "meta": {
    "provider": "mock",
    "ttlSeconds": 120,
    "fetchedAt": "2026-04-10T12:00:00.000Z",
    "cached": false
  }
}
```

## 错误响应（示例）

**400 Bad Request**

```json
{
  "statusCode": 400,
  "message": [
    "latitude must be a latitude",
    "longitude must be a longitude"
  ],
  "error": "Bad Request"
}
```
