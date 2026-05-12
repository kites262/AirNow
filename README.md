<div align="center">

# AirNow

**空气质量实时监测**

追踪 AQI、六项污染物浓度与 24 小时趋势，辅以天气预报。

[在线体验](https://your-domain.com) · [架构文档](docs/architecture.md) · [API 文档](apps/server/docs/api.md)

</div>

---

## 设计理念

空气质量的变化往往比天气更剧烈——一场雾霾可以在几小时内从轻度飙到重度。AirNow 的核心目标是让你随时掌握**当前空气状况和未来走向**，而非堆砌气象数据。

页面呈现：

- AQI 实时数值、等级与健康建议
- PM2.5 / PM10 / SO₂ / NO₂ / O₃ / CO 逐项浓度
- 未来 24 小时 AQI 逐小时趋势
- 未来数日气温与湿度（辅助判断污染物扩散条件）

天气服务于空气质量判断，而非主角。

## 架构

```
AirNow/
├── apps/
│   ├── web/          Vue 3 + Vite，移动端优先
│   ├── server/       NestJS API，聚合 · 缓存 · 校验
│   └── android/      WebView 宿主，加载远端 H5
└── packages/
    └── shared/       前后端共享类型契约
```

Server 产出数据，Web 渲染界面，Android 承载分发。`packages/shared` 维护接口契约，两端类型始终同步。

## 快速开始

```bash
pnpm install
pnpm dev
```

前端 `localhost:5173`，后端 `localhost:3000`，代理已就绪。

```bash
pnpm dev:web        # 仅前端
pnpm dev:server     # 仅后端
pnpm build          # 构建全部
pnpm typecheck      # 类型检查
```

## 环境变量

后端 `apps/server/.env`：

```bash
PORT=3000
API_PREFIX=/api
WEATHER_PROVIDER=mock        # mock 无需密钥，开箱即用
QWEATHER_HOST=https://devapi.qweather.com
QWEATHER_TOKEN=your-token
```

前端 `apps/web/.env`：

```bash
VITE_API_BASE=/api
VITE_PROXY_TARGET=http://localhost:3000
```

`mock` 模式可离线运行；切至 `qweather` 需配置和风天气 Token。

## API

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/api/health` | 服务探活 |
| `POST` | `/api/dashboard` | 经纬度 → 完整仪表盘 |

请求示例：

```json
{ "latitude": 39.9042, "longitude": 116.4074 }
```

响应包含 `location`、`air`、`airHourlyForecast`、`forecast`、`meta` 五个字段。
详见 [`apps/server/docs/api.md`](apps/server/docs/api.md)。

## Android

极简 WebView 宿主。加载远端 H5，处理定位权限，外链交由系统浏览器。

```bash
cd apps/android
./gradlew assembleDebug --no-daemon
```

产物路径：`app/build/outputs/apk/debug/app-debug.apk`

包名 `com.example.airnow`（可通过 `local.properties` 配置），入口 `https://your-domain.com`。

## 技术栈

| 层 | 选型 |
|----|------|
| 前端 | Vue 3 · Vite · TypeScript |
| 后端 | NestJS · TypeScript · Axios |
| 契约 | `@airnow/shared` |
| 图表 | 自绘 SVG |
| 数据源 | 和风天气 / Mock Provider |
| 缓存 | 内存 Map |
| 宿主 | Kotlin · WebView |

## 部署

```bash
pnpm --filter @airnow/web build
cd apps/server && pm2 start dist/main.js --name airnow-api
```

Caddy / Nginx 反向代理：

- `/` → 前端静态文件
- `/api` → 后端服务

同域部署，无需 CORS 配置。

## License

[MIT](LICENSE)
