# Server

`apps/server` 是 AirNow 的后端 API 服务，基于 NestJS 构建。

## 职责

- 接收经纬度，返回当前空气质量、未来 24 小时 AQI 趋势与未来天气趋势
- 通过内存缓存减少真实第三方 API 调用次数
- 聚合 QWeather / Mock provider，并输出统一的 dashboard 结构
- 与 `packages/shared` 共享前后端契约类型

## 结构

```text
apps/server
├── src
│   ├── app.module.ts
│   ├── config.ts
│   ├── main.ts
│   └── modules
│       ├── dashboard
│       │   ├── dashboard-cache.service.ts
│       │   ├── dashboard.controller.ts
│       │   ├── dashboard.dto.ts
│       │   ├── dashboard.module.ts
│       │   ├── dashboard.service.ts
│       │   ├── dashboard.tokens.ts
│       │   ├── dashboard.types.ts
│       │   ├── location-resolver.ts
│       │   ├── mock-weather-provider.service.ts
│       │   └── qweather-provider.service.ts
│       └── health
│           ├── health.controller.ts
│           └── health.module.ts
├── docs
│   ├── api.md
│   ├── dashboard.http
│   └── health.http
├── .env.example
├── package.json
└── tsconfig.json
```

## 配置

参考 [.env.example](/home/kites/projects/AirNow/apps/server/.env.example)：

```bash
PORT=3000
API_PREFIX=/api
WEATHER_PROVIDER=mock
QWEATHER_HOST=https://devapi.qweather.com
QWEATHER_TOKEN=your-token
```

默认可使用 `WEATHER_PROVIDER=mock` 进行本地联调；切换到 `qweather` 时需要配置 `QWEATHER_TOKEN`。

## 模块

### `health`

确认服务是否可用

- `GET /api/health`

### `dashboard`

核心模块

- `POST /api/dashboard`

`DashboardService` 负责缓存命中判断与统一返回结构，provider 只负责生成快照。

## 相关文档

- [api.md](/home/kites/projects/AirNow/apps/server/docs/api.md)
- [dashboard.http](/home/kites/projects/AirNow/apps/server/docs/dashboard.http)
- [health.http](/home/kites/projects/AirNow/apps/server/docs/health.http)
