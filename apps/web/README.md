# Web

`apps/web` 是 AirNow 的移动端前端页面，基于 Vue 3 + Vite 构建，以 H5 页面形式展示天气和空气质量数据，并由 Android WebView 宿主加载。

当前版本重点是先打通页面展示、交互状态和后端接口消费，不依赖数据库，也不引入复杂状态管理。

## 职责

- 作为移动端展示层，负责渲染 AQI、污染物、未来 24 小时 AQI 趋势和未来天气趋势
- 调用后端统一接口，不在浏览器里直接访问第三方天气服务
- 管理页面加载、错误、空状态、城市切换和刷新交互
- 启动后先用默认坐标加载，再尝试通过 H5 Geolocation 更新当前位置
- 通过 `packages/shared` 复用 dashboard 请求/响应契约

## 源码结构

```text
apps/web
├── config.ts
├── src
│   ├── main.ts
│   ├── App.vue
│   ├── config.ts
│   ├── style.css
│   ├── env.d.ts
│   ├── composables
│   │   └── useDashboard.ts
│   ├── components
│   │   ├── AirQualityCard.vue
│   │   ├── ForecastChart.vue
│   │   ├── HourlyAirForecastCard.vue
│   │   ├── LocationHeader.vue
│   │   ├── PollutantGrid.vue
│   │   └── StatusOverlay.vue
├── .env.example
├── index.html
├── package.json
├── vite.config.ts
└── tsconfig.json
```

## 文件职责

### 入口与全局配置

- [src/main.ts](/home/kites/projects/AirNow/apps/web/src/main.ts)
  创建 Vue 应用并挂载根组件
- [src/App.vue](/home/kites/projects/AirNow/apps/web/src/App.vue)
  负责页面骨架、城市切换、模块组合、首次数据加载和 H5 定位触发
- [src/style.css](/home/kites/projects/AirNow/apps/web/src/style.css)
  定义整体视觉风格、卡片布局和移动端适配样式
- [config.ts](/home/kites/projects/AirNow/apps/web/config.ts)
  定义前端运行配置与 Vite 共享的环境变量解析逻辑
- [src/config.ts](/home/kites/projects/AirNow/apps/web/src/config.ts)
  为应用运行时代码提供轻量配置入口
- [vite.config.ts](/home/kites/projects/AirNow/apps/web/vite.config.ts)
  配置 Vite 开发服务器和 `/api` 代理，方便本地联调

### 数据请求与类型

- [src/composables/useDashboard.ts](/home/kites/projects/AirNow/apps/web/src/composables/useDashboard.ts)
  负责仪表盘数据请求、加载状态、错误状态和刷新逻辑
- [packages/shared](/home/kites/projects/AirNow/packages/shared)
  维护前后端共享的 dashboard 契约，`web` 直接从 `@airnow/shared` 引用公共类型

这里把请求逻辑和视图组件分开，后面如果要接入轮询、缓存恢复或更复杂的数据源，也只需要在 composable 层扩展。

### 展示组件

- [src/components/LocationHeader.vue](/home/kites/projects/AirNow/apps/web/src/components/LocationHeader.vue)
  保留的头部展示组件，可用于独立展示当前城市、经纬度、Provider 和刷新时间
- [src/components/AirQualityCard.vue](/home/kites/projects/AirNow/apps/web/src/components/AirQualityCard.vue)
  展示 AQI 主数值、等级、健康建议和六项污染物指标
- [src/components/PollutantGrid.vue](/home/kites/projects/AirNow/apps/web/src/components/PollutantGrid.vue)
  保留的独立污染物面板组件
- [src/components/HourlyAirForecastCard.vue](/home/kites/projects/AirNow/apps/web/src/components/HourlyAirForecastCard.vue)
  使用轻量 SVG 渲染未来 24 小时 AQI 趋势
- [src/components/ForecastChart.vue](/home/kites/projects/AirNow/apps/web/src/components/ForecastChart.vue)
  使用轻量 SVG 渲染温度趋势，并列出每日温度与湿度
- [src/components/StatusOverlay.vue](/home/kites/projects/AirNow/apps/web/src/components/StatusOverlay.vue)
  统一承接加载中、错误和空数据状态

## 页面交互流程

1. 页面启动后，`App.vue` 在 `onMounted` 中调用 `useDashboard().load()`
2. `useDashboard` 向 `/api/dashboard` 发起 POST 请求，请求体只有 `latitude` 与 `longitude`
3. 请求完成后，响应数据保存到 `data`
4. `App.vue` 根据返回结果渲染位置、AQI、未来 24 小时 AQI 趋势和天气趋势图
5. 如果浏览器或 WebView 授权定位，`App.vue` 会用当前位置再次调用 `load({ latitude, longitude })`
6. 用户切换预置城市时，再次调用 `load({ latitude, longitude })`
7. 如果请求失败，则 `StatusOverlay` 展示错误态并允许重试

## 为什么这样拆分

- 页面骨架和业务请求分离，便于后续引入更多页面或状态管理方案
- 组件职责单一，便于替换 UI 或接入图表库
- 共享契约集中在 `packages/shared`，避免前后端模型漂移
- Android WebView 只负责承载页面与权限授权，前端仍然只处理“坐标输入 -> 数据展示”这一件事

## 后续扩展建议

- 增强定位状态反馈，例如区分默认坐标、预置城市和真实定位
- 用 ECharts 替换当前 SVG 趋势图，实现更完整的交互和多序列展示
- 增加轮询、下拉刷新或缓存恢复能力
- 继续拆分为 `views`、`services`、`stores` 目录，支撑更复杂页面
