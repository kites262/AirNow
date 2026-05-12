#import "mytemplate.typ": project
#import "config.typ": authors, mentors

#page(margin: 0pt, footer: none)[
  #image("figures/cover.pdf", width: 100%, height: 100%, fit: "contain")
]
#counter(page).update(1)

#show: project.with(
  title: "雾霾探测系统设计",
  subtitle: "空气质量实时监测系统 AirNow",
  authors: authors,
  mentors: mentors,
  academic-year: "2026.5.11",
  footer-text: "B级能力达标测试",
  school-logo: none,
)


#let node(body, fill: rgb("#eef2ff"), stroke: 0.6pt + rgb("#475569"), w: auto) = box(
  fill: fill,
  stroke: stroke,
  radius: 4pt,
  inset: (x: 8pt, y: 6pt),
  width: w,
)[#align(center)[#text(size: 9.5pt)[#body]]]

#let flow-card(title, body, fill: rgb("#eef2ff"), stroke: 0.6pt + rgb("#475569"), w: auto) = box(
  fill: fill,
  stroke: stroke,
  radius: 4pt,
  inset: (x: 7pt, y: 5pt),
  width: w,
)[
  #align(center)[#text(weight: "bold", size: 9.2pt)[#title]]
  #v(2pt)
  #align(left)[#text(size: 8pt, gray)[#body]]
]

#let flow-down(body) = align(center)[
  #text(size: 8pt, gray)[#body]
  #v(-3pt)
  #text(size: 11pt)[↓]
]

#let arrow(body: none) = {
  if body == none {
    text(size: 11pt)[→]
  } else {
    align(center)[
      #text(size: 8.5pt)[#body]
      #v(-4pt)
      #text(size: 11pt)[→]
    ]
  }
}

#let polyline(stroke: none, ..pts) = {
  let points = pts.pos()
  curve(
    stroke: stroke,
    curve.move(points.first()),
    ..points.slice(1).map(p => curve.line(p)),
  )
}

#show figure.where(kind: image): set figure(supplement: [图])
#show figure.where(kind: table): set figure(supplement: [表])
#set figure(placement: none)


= 问题描述

== 背景

近年来，雾霾已成为我国城市频发的环境问题，尤其在秋冬两季，以 PM2.5 为主的细颗粒物污染常常在多座大中城市同时出现。雾霾不仅显著降低能见度，还会通过呼吸道进入肺部和血液循环系统，加重呼吸系统疾病并对心血管健康造成长期影响。在这样的背景下，了解所在地的实时空气质量指数（AQI）已成为公众日常生活的基本需求之一。

雾霾天气直接影响居民的出行决策。是否开窗通风、是否进行户外锻炼、是否需要佩戴口罩、是否带儿童外出等问题，都依赖于对当前与未来一段时间内空气质量的判断。然而，公众获取空气质量数据的渠道并不统一：传统天气应用以温度、降水为核心，AQI 通常被折叠在次要位置；专业的环境监测平台又较为分散。用户希望在出行前，于一处简洁的界面中即时掌握所在城市的 AQI、主要污染物浓度以及未来一段时间的变化趋势。

正是基于上述需求，本课程项目以"雾霾探测"为主题，设计并实现了一款移动端空气质量实时监测系统 AirNow，让用户随时随地掌握当前空气状况与未来走向，从而为日常出行与健康防护提供参考。

== 课程任务要求

本课程的设计任务围绕"雾霾探测"展开，核心关注定位、数据获取、界面呈现与报告四个维度，如@tab-requirements 所示。任务说明同时给出了实现技术指引：可使用百度地图、高德地图等服务获取定位，使用和风天气、墨迹天气等服务获取天气与空气质量数据；界面建议使用 HTML5 解决手机像素适配问题，主体由定位栏（Header）与正文（Body）两部分构成，正文中需包含天气、空气质量指数动态显示与温湿度折线图。

#figure(
  table(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    stroke: 0.5pt,
    table.header([*序号*], [*需求*], [*需求解读*]),
    [1],
    [*定位功能*],
    [将定位城市保存在服务器端，并同时显示在客户端。客户端需获取用户位置，服务端需识别并存储定位信息，客户端展示定位结果。],

    [2],
    [*界面设计*],
    [包含显示天气和空气质量指数的动态显示。界面需美观易操作，数据需以动画或图表等动态方式呈现。],

    [3],
    [*天气详情与空气质量指数*],
    [定位后的城市在服务端获取，通过天气 API 获取详情并缓存。客户端不直接访问第三方服务。],

    [4],
    [*完成报告*],
    [方案设计、结果分析与报告完整性，配套实验编码测试。],
  ),
  caption: [课程任务需求概述],
) <tab-requirements>

== 项目目标

本项目以系统名 AirNow 实现一套面向移动端的空气质量实时监测系统。系统的核心功能围绕"空气质量"这一主角展开：在主界面集中呈现当前 AQI 数值与等级、PM2.5/PM10/SO#sub[2]/NO#sub[2]/O#sub[3]/CO 六项污染物浓度、未来 24 小时的逐小时 AQI 趋势，以及未来数日的气温与湿度走向。设计上将 AQI 置于视觉中心位置，将天气作为辅助信息呈现，用以判断污染物的扩散条件，例如低温高湿天气下污染物不易扩散、AQI 容易抬升。系统采用 H5 移动端优先 + Android WebView 宿主 App 的分发方式，既能在浏览器中直接打开，又能以原生 App 形式安装。

在技术实现上，定位功能基于浏览器 H5 Geolocation API 实现，并在 Android 端通过 `WebChromeClient` 完成跨层权限桥接；界面设计采用暗色毛玻璃风格的卡片化布局，结合 AQI 环形进度动画与自绘 SVG 折线图实现动态数据呈现；空气质量指数与天气详情通过和风天气（QWeather）API 在服务端聚合，并以内存缓存复用结果，对客户端屏蔽底层接口差异。

= 方案设计

== 系统总体架构

本系统采用 Monorepo 方式组织源码，统一由 pnpm workspace 管理，分为四个模块：`apps/web`（Vue 3 实现的前端 H5）、`apps/server`（NestJS 实现的后端 API）、`apps/android`（Kotlin 实现的 WebView 宿主 App）以及 `packages/shared`（前后端共享类型契约包）。这种组织方式让前后端代码与共享类型位于同一仓库，便于跨模块重构与依赖管理。

架构层面的核心设计原则包括四点：第一，前端不直接调用第三方天气服务，所有外部请求均经由后端统一代理，从而保证 API 密钥不暴露、请求可控、结果可缓存；第二，后端对外暴露统一的领域模型 `DashboardResponse`，屏蔽底层 API 差异，前端只需面向业务模型开发；第三，Android 端仅作为宿主加载可信的 H5 站点，业务逻辑集中在 Web 与 Server，避免在原生侧维护重复实现；第四，`packages/shared` 集中维护接口契约，借助 TypeScript 在编译期同步前后端类型。一句话概括：Server 产出数据，Web 渲染界面，Android 承载分发，Shared 维护契约。系统总体架构如@fig-arch 所示。

#figure(
  kind: image,
  block(width: 100%)[
    #grid(
      columns: (1fr, auto, 1.1fr, auto, 1.1fr, auto, 1.1fr, auto, 1.2fr),
      column-gutter: 4pt,
      row-gutter: 6pt,
      align: (center + horizon),
      node([用户]),
      arrow(),
      node([Android WebView \ / 浏览器]),
      arrow(body: [加载]),
      node([Web H5 \ Vue 3 + Vite], fill: rgb("#dbeafe")),
      arrow(body: [POST /api/dashboard \ \{lat, lon\}]),
      node([Server API \ NestJS \ + CacheService], fill: rgb("#fef3c7")),
      arrow(body: [HTTP]),
      node([QWeather \ / Mock Provider], fill: rgb("#dcfce7")),
    )
    #v(8pt)
    #align(center)[
      #grid(
        columns: (auto, 1fr, auto),
        column-gutter: 16pt,
        align: (center + horizon),
        text(size: 9pt)[
          #box(stroke: (dash: "dashed", thickness: 0.5pt), inset: 4pt, radius: 3pt)[
            Web H5 ⇠⇢ packages/shared ⇠⇢ Server API \ #text(gray)[（编译期类型契约共享）]
          ]
        ],
        [],
        text(size: 9pt)[
          #box(stroke: (dash: "dashed", thickness: 0.5pt), inset: 4pt, radius: 3pt)[
            Android WebView ⇠⇢ Web H5 \ #text(gray)[（H5 Geolocation 定位桥接）]
          ]
        ],
      )
    ]
    #v(4pt)
    #align(center)[
      #text(size: 8.5pt, gray)[
        实线：HTTP 调用与数据流；虚线：类型契约共享与跨层权限桥接
      ]
    ]
  ],
  caption: [系统总体架构图],
) <fig-arch>

#v(6pt)

首页打开后，前端、后端、缓存与 Provider 之间的协作过程可由一次完整的数据加载交互体现，其时序如@fig-dataflow 所示。

#figure(
  kind: image,
  block(width: 100%)[
    #set text(size: 9pt)
    #grid(
      columns: (1fr, auto, 1.1fr, auto, 1.1fr, auto, 1fr),
      column-gutter: 4pt,
      align: (center + horizon),
      flow-card([用户], [打开首页], fill: rgb("#eef2ff"), w: 100%),
      arrow(),
      flow-card([Web H5], [`POST /api/dashboard` \ 默认坐标或定位坐标], fill: rgb("#dbeafe"), w: 100%),
      arrow(),
      flow-card([Server API], [校验请求 \ 计算 `lat:lon` 缓存键], fill: rgb("#fef3c7"), w: 100%),
      arrow(),
      flow-card([CacheService], [读取快照并检查 TTL], fill: rgb("#fef3c7"), w: 100%),
    )
    #v(6pt)
    #flow-down([缓存是否命中])
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 12pt,
      align: (center + top),
      [
        #align(center)[#text(weight: "bold", size: 8.5pt)[命中]]
        #flow-down([])
        #flow-card([返回缓存快照], [必要时补全 `location.detail` \ `meta.cached = true`], fill: rgb("#dcfce7"), w: 100%)
      ],
      [
        #align(center)[#text(weight: "bold", size: 8.5pt)[未命中]]
        #flow-down([])
        #flow-card(
          [Provider 生成快照],
          [`createDashboardSnapshot(request)` \ 写入缓存 TTL 300s / 120s],
          fill: rgb("#fce7f3"),
          w: 100%,
        )
      ],
    )
    #flow-down([返回 DashboardResponse])
    #align(center)[
      #flow-card(
        [Web H5 渲染界面],
        [AQI 卡片 / 24h 趋势 / 多日天气趋势 \ 定位成功后以真实坐标静默刷新],
        fill: rgb("#dbeafe"),
        w: 62%,
      )
    ]
  ],
  caption: [系统数据流图（首页加载时序）],
) <fig-dataflow>

== 前端方案

前端采用 Vue 3 + Vite + TypeScript 的单页应用结构，整体面向移动端设计。`app-shell` 容器以 `max-width: 520pt`（折合约 520px）居中布局以模拟手机宽度，并设置 `min-width: 320px` 以适配小屏机型。图表方案上摒弃 ECharts 等第三方库，转而完全自绘 SVG：考虑到本项目仅需三种折线图与一种环形进度图，自绘 SVG 既轻量、可精确控制样式，又便于与暗色主题深度融合，避免引入第三方主题适配负担。

数据层基于 Composable 模式实现：`useDashboard` 封装请求、加载、错误与重试状态，组件通过 `data`、`loading`、`error` 等响应式字段订阅数据。页面 `onMounted` 阶段先以默认坐标加载首屏，后续若定位成功则以真实坐标静默刷新。整个 UI 由 6 个组件组成：`App.vue` 担任根编排，负责城市切换、定位触发与滚动渐入动画的总控；`AirQualityCard.vue` 呈现 AQI 环形动画、等级文字与六项污染物面板；`HourlyAirForecastCard.vue` 与 `ForecastChart.vue` 分别承担 24 小时 AQI 折线图与多日天气趋势图（含温度双折线与湿度折线）；`StatusOverlay.vue` 提供加载、错误与空态三态展示；`LocationHeader.vue` 与 `PollutantGrid.vue` 作为可复用的备用组件保留。组件关系流向如@fig-frontend 所示。

#figure(
  kind: image,
  block(width: 100%)[
    #set text(size: 9pt)
    #align(center)[
      #flow-card([App.vue], [根编排：城市切换 / 定位触发 / 滚动渐入], fill: rgb("#eef2ff"), w: 48%)
    ]
    #flow-down([分发状态与用户事件])
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 8pt,
      row-gutter: 8pt,
      align: (center + top),
      flow-card([Hero Card], [定位信息 \ 城市选择入口], fill: rgb("#dbeafe"), w: 100%),
      flow-card([City Picker Modal], [`<Transition>` \ 2 列城市标签], fill: rgb("#dbeafe"), w: 100%),
      flow-card([StatusOverlay], [loading / error / empty], fill: rgb("#fef3c7"), w: 100%),
    )
    #flow-down([data 可用时渲染 Dashboard Content])
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 8pt,
      row-gutter: 8pt,
      align: (center + top),
      flow-card(
        [AirQualityCard],
        [AQI Ring \ Level Text + Advice \ PM2.5 / PM10 / SO2 / NO2 / O3 / CO],
        fill: rgb("#dcfce7"),
        w: 100%,
      ),
      flow-card(
        [HourlyAirForecastCard],
        [摘要标签 \ SVG Line Chart \ 24h AQI 趋势],
        fill: rgb("#dcfce7"),
        w: 100%,
      ),
      flow-card([ForecastChart], [SVG Dual-Line Chart + Humidity Line \ Forecast Strip \ 多日天气趋势], fill: rgb("#dcfce7"), w: 100%),
    )
    #flow-down([展示运行元信息])
    #align(center)[
      #flow-card([Footer Note], [Provider / 缓存状态 / 时间戳], fill: rgb("#f8fafc"), w: 44%)
    ]
  ],
  caption: [前端组件关系流图],
) <fig-frontend>

视觉风格采用暗色毛玻璃风格，背景叠加渐变光晕营造层次。动画包含四类：页面入场缓动、滚动渐入、AQI 数值计数动画与卡片交错入场，使加载时呈现自上而下的视觉节奏。AQI 环形进度的视觉构成与颜色映射如@fig-aqi-ring 所示。

#figure(
  kind: image,
  block(width: 100%)[
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 16pt,
      align: (center + horizon),
      [
        #box(
          width: 95pt,
          height: 95pt,
        )[
          #place(center + horizon)[
            #circle(radius: 42pt, stroke: 9pt + rgb("#1f2937"))
          ]
          #place(center + horizon)[
            #circle(radius: 42pt, stroke: (paint: rgb("#34d399"), thickness: 9pt, dash: (18pt, 200pt)))
          ]
          #place(center + horizon)[
            #stack(spacing: 2pt)[
              #text(size: 18pt, weight: "bold")[35]
            ][
              #text(size: 8pt, gray)[AQI · 优]
            ]
          ]
        ]
        #v(4pt)
        #text(size: 8.5pt, gray)[AQI = 35 #sym.arrow 进度 63°]
      ],
      [
        #box(
          width: 95pt,
          height: 95pt,
        )[
          #place(center + horizon)[
            #circle(radius: 42pt, stroke: 9pt + rgb("#1f2937"))
          ]
          #place(center + horizon)[
            #circle(radius: 42pt, stroke: (paint: rgb("#fb7185"), thickness: 9pt, dash: (155pt, 110pt)))
          ]
          #place(center + horizon)[
            #stack(spacing: 2pt)[
              #text(size: 18pt, weight: "bold")[120]
            ][
              #text(size: 8pt, gray)[AQI · 轻度]
            ]
          ]
        ]
        #v(4pt)
        #text(size: 8.5pt, gray)[AQI = 120 #sym.arrow 进度 216°]
      ],
    )
    #v(10pt)
    #align(center)[
      #grid(
        columns: 4,
        column-gutter: 14pt,
        row-gutter: 4pt,
        align: center,
        [#box(width: 12pt, height: 12pt, fill: rgb("#34d399"), radius: 2pt)],
        [#box(width: 12pt, height: 12pt, fill: rgb("#fbbf24"), radius: 2pt)],
        [#box(width: 12pt, height: 12pt, fill: rgb("#fb7185"), radius: 2pt)],
        [#box(width: 12pt, height: 12pt, fill: rgb("#f97316"), radius: 2pt)],

        text(size: 9pt)[优 ≤50], text(size: 9pt)[良 ≤100], text(size: 9pt)[轻度 ≤150], text(size: 9pt)[中度 >150],
      )
    ]
    #v(4pt)
    #align(center)[
      #text(size: 8.5pt, gray)[
        进度公式：`--aqi-progress = min(AQI, 200) / 200 * 360deg` ；动画：1100ms `easeOutCubic` 数值与颜色同步过渡
      ]
    ]
  ],
  caption: [AQI 环形进度动画示意图],
) <fig-aqi-ring>

== 后端方案

后端采用 NestJS + TypeScript，模块化架构使各功能边界清晰。系统包含两个业务模块：`HealthModule` 提供 `GET /health` 探活接口，返回 `{ ok, timestamp, service }` 用于健康检查；`DashboardModule` 是核心业务模块，包含 10 个源文件，覆盖控制器、服务、Provider 与缓存层。模块之间的依赖关系如@fig-backend-module 所示。

#figure(
  kind: image,
  block(width: 100%)[
    #set text(size: 9pt)
    #align(center)[
      #flow-card([AppModule], [应用根模块], fill: rgb("#eef2ff"), w: 40%)
    ]
    #flow-down([注册业务模块])
    #grid(
      columns: (0.9fr, 1.4fr),
      column-gutter: 14pt,
      align: (center + top),
      [
        #flow-card([HealthModule], [健康检查模块], fill: rgb("#dcfce7"), w: 100%)
        #flow-down([])
        #flow-card([HealthController], [`GET /health` \ ok / timestamp / service], fill: rgb("#f8fafc"), w: 100%)
      ],
      [
        #flow-card([DashboardModule], [核心业务模块], fill: rgb("#dbeafe"), w: 100%)
        #flow-down([])
        #grid(
          columns: (1fr, auto, 1fr),
          column-gutter: 4pt,
          align: (center + horizon),
          flow-card([DashboardController], [`POST /api/dashboard`], fill: rgb("#f8fafc"), w: 100%),
          arrow(),
          flow-card([DashboardService], [请求编排 / 响应组装], fill: rgb("#fef3c7"), w: 100%),
        )
        #flow-down([调用依赖])
        #grid(
          columns: (1fr, 1fr, 1fr),
          column-gutter: 6pt,
          row-gutter: 6pt,
          align: (center + top),
          flow-card([Dashboard \ CacheService], [缓存读写], fill: rgb("#eef2ff"), w: 100%),
          flow-card([Nominatim \ Service], [detail 补全], fill: rgb("#eef2ff"), w: 100%),
          flow-card([WEATHER \ PROVIDER], [Symbol token 注入], fill: rgb("#fce7f3"), w: 100%),
        )
        #flow-down([useFactory 选择实现])
        #grid(
          columns: (1fr, 1fr),
          column-gutter: 8pt,
          align: (center + top),
          flow-card([QWeather \ ProviderService], [真实天气数据], fill: rgb("#dcfce7"), w: 100%),
          flow-card([MockWeather \ ProviderService], [本地演示数据], fill: rgb("#dcfce7"), w: 100%),
        )
      ],
    )
  ],
  caption: [后端模块依赖流图],
) <fig-backend-module>

后端最具代表性的设计是 Provider 抽象层。系统定义统一的天气数据提供者接口，真实数据源（和风天气）与模拟数据源分别实现该接口，由服务容器根据环境配置自动注入对应实现。这一设计带来三个好处：第一，切换数据源只需修改配置，业务代码无需改动；第二，新增数据源只需实现接口并注册，不影响已有逻辑；第三，模拟数据源使系统在无 API 密钥时仍可完整运行，支撑本地联调与课程演示。从架构演进的角度看，Provider 抽象将"数据从哪里来"与"数据怎么用"彻底解耦，使得上层业务逻辑只需关心共享契约定义的数据结构，而无需感知底层接口差异与认证方式。此外，这种契约驱动的分层也为后续接入更多数据源（如其他天气服务商或本地气象站）预留了扩展空间，避免了为新数据源而大面积修改既有代码的风险。Provider 的抽象与切换机制如@fig-provider 所示。

#figure(
  kind: image,
  block(width: 100%)[
    #align(center)[
      #node([*DashboardService* \ `inject(WEATHER_PROVIDER)`], fill: rgb("#fef3c7"), w: 60%)
    ]
    #v(6pt)
    #align(center)[
      #grid(
        columns: (1fr, auto, 1fr),
        align: (center + horizon),
        text(size: 8.5pt)[`config.weatherProvider = "qweather"`],
        text(size: 9pt)[← `useFactory` →],
        text(size: 8.5pt)[`config.weatherProvider = "mock"`],
      )
    ]
    #v(4pt)
    #align(center)[
      #grid(
        columns: (1fr, 1fr),
        column-gutter: 24pt,
        node([*QWeatherProviderService* \ `implements DashboardWeatherProvider`], fill: rgb("#dcfce7")),
        node([*MockWeatherProviderService* \ `implements DashboardWeatherProvider`], fill: rgb("#dbeafe")),
      )
    ]
    #v(6pt)
    #align(center)[
      #text(size: 9pt)[#sym.arrow.b.double 统一接口输出 #sym.arrow.b.double]
    ]
    #v(4pt)
    #align(center)[
      #node([*DashboardSnapshot* #text(size: 8pt)[（前端无感知差异）]], fill: rgb("#fce7f3"), w: 50%)
    ]
  ],
  caption: [Provider 抽象与切换机制图],
) <fig-provider>

围绕 Provider 之外，`DashboardService` 担任编排层，统一处理缓存命中判断、Provider 调用、Nominatim detail 补全与响应组装；`DashboardCacheService` 承载缓存层，使用进程内 `Map` 存储 `CacheEntry`，缓存 Key 为 `lat.toFixed(4):lon.toFixed(4)`，过期采用懒淘汰策略。请求侧统一启用全局 `ValidationPipe`，配合 `class-validator`（如 `@IsLatitude` / `@IsLongitude`）和 `class-transformer`（`@Type`），开启 `whitelist` 与 `forbidNonWhitelisted` 拒绝多余字段，并通过 `transform` 自动完成类型转换。错误策略采取分层处理：必需数据（如核心 AQI 接口）失败即抛出 `BadGatewayException(502)`；可选数据（如 Geo 解析、Nominatim detail）失败则静默降级返回 `null`，不影响整体响应。

== Android 方案

Android 端采用 Kotlin + AndroidX AppCompat + WebKit 技术栈，`minSdk 24`、`targetSdk 34`，包名通过 `BuildConfig.APP_PACKAGE` 注入。其架构定位非常明确：作为极简的 WebView 宿主，不承担任何原生业务逻辑，所有 UI 与数据交互均由远端 H5 完成。App 启动后直接加载由 `BuildConfig.WEB_URL` 注入的入口 URL。原生侧的核心职责包括三项：第一，WebView 初始化，启用 JS、DOM Storage、Viewport，禁用缩放控件，使用默认缓存策略；第二，导航拦截，`AirNowWebViewClient.shouldOverrideUrlLoading` 区分同域 URL 与外链——同域在 WebView 内加载，外链则启动系统浏览器（`Intent.ACTION_VIEW`）；第三，定位权限桥接，`AirNowWebChromeClient.onGeolocationPermissionsShowPrompt` 拦截 H5 的 geolocation 请求，配合 Android Runtime Permission 完成跨层授权。

生命周期管理上，`onPause` / `onResume` 委托 WebView 自身实现，`onDestroy` 阶段执行严格的销毁流程：停止加载 → 禁用 JS → 加载 `about:blank` → 清除历史 → 从父视图移除 → 调用 `destroy()`，避免残留引用与内存泄漏。返回导航通过 `OnBackPressedCallback` 优先调用 `WebView.goBack()`，无法回退时再交由系统处理。`onSaveInstanceState` 保存 WebView 状态，`onCreate` 阶段恢复，从而支持横竖屏切换等系统重建场景。其中最关键的定位权限跨层授权流程如@fig-android-geolocation 所示。

#figure(
  kind: image,
  block(width: 100%)[
    #set text(size: 9pt)
    #grid(
      columns: (1fr, auto, 1.1fr, auto, 1fr),
      column-gutter: 4pt,
      align: (center + horizon),
      flow-card([H5 页面], [`navigator.geolocation` 发起定位], fill: rgb("#eef2ff"), w: 100%),
      arrow(),
      flow-card([WebChromeClient], [`onGeolocationPermissionsShowPrompt` 拦截请求], fill: rgb("#dbeafe"), w: 100%),
      arrow(),
      flow-card([MainActivity], [`hasLocationPermissions()` 检查权限], fill: rgb("#fef3c7"), w: 100%),
    )
    #flow-down([权限判断])
    #align(center)[
      #flow-card([是否已授权], [ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION], fill: rgb("#fef3c7"), w: 46%)
    ]
    #v(2pt)
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 12pt,
      align: (center + top),
      [
        #align(center)[#text(weight: "bold", size: 8.5pt)[已授权]]
        #flow-down([])
        #flow-card([直接回调 H5], [`callback.invoke(origin, true, false)`], fill: rgb("#dcfce7"), w: 100%)
        #flow-down([])
        #flow-card([H5 获得定位], [继续加载空气质量数据], fill: rgb("#eef2ff"), w: 100%)
      ],
      [
        #align(center)[#text(weight: "bold", size: 8.5pt)[未授权]]
        #flow-down([])
        #flow-card(
          [暂存请求],
          [`pendingGeolocationCallback` \ `pendingGeolocationOrigin`],
          fill: rgb("#fce7f3"),
          w: 100%,
        )
        #flow-down([])
        #flow-card(
          [Android 系统弹窗],
          [`locationPermissionLauncher.launch` \ 用户授权或拒绝],
          fill: rgb("#eef2ff"),
          w: 100%,
        )
        #flow-down([])
        #flow-card(
          [回传授权结果],
          [`ActivityResultCallback` \ `pendingGeolocationCallback.invoke(granted)`],
          fill: rgb("#dcfce7"),
          w: 100%,
        )
      ],
    )
  ],
  caption: [Android WebView 定位权限桥接流程图],
) <fig-android-geolocation>

== 共享契约

在前后端分离的架构中，接口契约的一致性是联调效率的关键保障。本项目将所有共享类型集中抽取到 `packages/shared` 包中，作为前后端之间的"单一事实来源"（Single Source of Truth）。该包是一个纯类型声明包（`.d.ts`），在运行时不产出任何 JavaScript 代码，仅通过 TypeScript 的 `import type` 语法被前后端静态引入，因此不会增加前端打包体积，也不会引入运行时依赖。

该包共定义了 15 个类型，按照数据流方向可划分为请求侧与响应侧两大类。请求侧仅有 `DashboardRequest`，定义了前端向后端发送的唯一入参结构，包含 `latitude` 与 `longitude` 两个必填数值字段，由 `class-validator` 的 `@IsLatitude` / `@IsLongitude` 装饰器在服务端进行校验。响应侧以 `DashboardSnapshot` 为核心，它由 `DashboardLocation`、`AirInfo`、`DashboardAirHourlyForecast`、`DashboardForecast` 与 `DashboardSnapshotMeta` 五个业务字段组合而成，再与 `{ cached: boolean }` 交叉类型合并，构成面向前端的顶层响应 `DashboardResponse`。其中，`DashboardLocation` 描述位置信息，包含城市、区县、街道级 detail 与经纬度；`AirInfo` 承载空气质量数据，包含 AQI 数值、等级文字、健康建议以及 `AirPollutants` 中六项污染物的浓度与单位；`DashboardAirHourlyForecast` 提供逐小时预报，内含 24 个 `AirHourlyForecastHour` 条目与逐小时污染物数组；`DashboardForecast` 涵盖多日天气预报，由 `ForecastDay` 数组与 `ForecastSeries` 温湿度序列组成；`DashboardSnapshotMeta` 则记录数据来源元信息，包括 Provider 名称、TTL 秒数、获取时间戳与缓存命中标记。此外，`WeatherProviderName`（`"qweather" | "mock"`）与 `AirMetricCode`（`"pm25" | "pm10" | ...`）等联合类型为字段取值提供了编译期约束。

由于前后端 `import` 的是同一份类型源文件，TypeScript 编译器在编译前后端项目时即可保证接口一致性。若后端修改了某个字段名称或类型，前端会在下次编译时立即收到类型错误提示，而非等到联调阶段才发现运行时报错。这一机制将接口集成问题从"运行时发现"前置到"编译期暴露"，从根本上杜绝了前后端字段漂移问题，显著降低了联调成本。重点契约 `DashboardResponse` 的字段嵌套与组合关系如@fig-contract 所示。

#figure(
  kind: image,
  block(width: 100%, stroke: 1pt + rgb("#475569"), inset: 8pt, radius: 4pt)[
    #set text(size: 9pt)
    #align(center)[
      #flow-card([DashboardResponse], [`DashboardSnapshot` & `{ cached: boolean }`], fill: rgb("#eef2ff"), w: 58%)
    ]
    #flow-down([组合为 5 个业务字段])
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 8pt,
      row-gutter: 8pt,
      align: (center + top),
      flow-card(
        [location],
        [`DashboardLocation` \ city / district / detail \ latitude / longitude],
        fill: rgb("#dbeafe"),
        w: 100%,
      ),
      flow-card([air], [`AirInfo` \ aqi / levelText / advice \ pollutants / unit], fill: rgb("#dcfce7"), w: 100%),
      flow-card(
        [airHourlyForecast],
        [`DashboardAirHourlyForecast` \ hours / pollutants / unit],
        fill: rgb("#dcfce7"),
        w: 100%,
      ),

      flow-card([forecast], [`DashboardForecast` \ days / series], fill: rgb("#fef3c7"), w: 100%),
      flow-card(
        [meta],
        [`DashboardSnapshotMeta` \ provider / ttlSeconds / fetchedAt \ cached],
        fill: rgb("#fce7f3"),
        w: 100%,
      ),
      flow-card(
        [shared types],
        [`WeatherProviderName` \ `AirMetricCode` \ `ForecastSeries`],
        fill: rgb("#f8fafc"),
        w: 100%,
      ),
    )
    #flow-down([前后端 import type 共享同一契约])
    #align(center)[
      #flow-card([编译期契约校验], [后端字段变化会直接暴露为前端 TypeScript 类型错误], fill: rgb("#eef2ff"), w: 62%)
    ]
  ],
  caption: [DashboardResponse 类型关系流图],
) <fig-contract>

= 数据获取

== 数据源选择

本项目选用和风天气（QWeather）作为主要数据源，主要基于五点考量：第一，QWeather 提供专门的空气质量接口（`/airquality/v1/`），数据完整度高，覆盖 AQI 数值、六项主要污染物浓度、等级文字与健康建议；第二，配套提供逐小时空气质量预报接口，恰好满足 24 小时趋势的需求；第三，提供 7 天天气预报（含温度与湿度），能够支撑"以天气辅助判断污染物扩散条件"的设计目标；第四，提供经纬度反向查询的城市解析接口，可由 GPS 定位反推城市/区县；第五，开发版 API 免费可用，适合课程项目场景。

在 QWeather 之外，系统同时保留了 `MockWeatherProviderService`，用于无 API 密钥的本地联调与课程演示降级。Mock 与真实 Provider 共享相同的接口契约，对前端完全透明，体现了 Provider 抽象的实际价值。

== QWeather Provider 接入

`QWeatherProviderService.createDashboardSnapshot` 是后端最复杂的方法之一，主要由 4 个 QWeather API 端点与 1 个 Nominatim 端点的并行调用与数据组装构成。四个 QWeather 端点的用途如@tab-qweather 所示，统一使用请求头 `X-QW-Api-Key: <QWEATHER_TOKEN>` 进行认证，URL 中的经纬度均四舍五入到 2 位小数以提升缓存命中率。

#figure(
  table(
    columns: (auto, 1.6fr),
    align: (left, left),
    stroke: 0.5pt,
    table.header([*端点*], [*用途*]),
    [`/airquality/v1/current/{lat}/{lon}`], [当前空气质量：AQI、污染物、等级、建议],
    [`/airquality/v1/hourly/{lat}/{lon}`], [逐小时空气质量预报（24h）],
    [`/v7/weather/7d?location={lon},{lat}`], [7 天天气预报（温度 + 湿度）],
    [`/geo/v2/city/lookup?location={lon},{lat}&lang=zh`], [城市位置反向解析],
  ),
  caption: [QWeather 接入端点],
) <tab-qweather>

QWeather 返回的原始数据结构与本项目共享契约（`DashboardSnapshot`）之间存在显著差异，需要一条完整的数据转换流水线将其适配为前端可消费的统一格式。原始响应来自 4 个不同端点，各自拥有独立的嵌套结构与命名约定；而 `DashboardSnapshot` 要求将空气质量、逐小时预报、天气预报与位置信息组织为四个平级字段，并保证每一项的数据类型与量纲统一。因此转换流水线的核心职责不仅是字段映射，更在于消除多源异构数据之间的语义与格式鸿沟。

转换流水线如@fig-pipeline 所示，共分四阶段。第一阶段为并行解析，通过 `Promise.all` 同时发起 5 个请求（4 个 QWeather + 1 个 Nominatim），最大化吞吐；各响应独立校验结构与必填字段，防止上游变更导致静默数据损坏。第二阶段为 AQI 指数选取，QWeather 的空气质量响应中包含多套指数体系（如国标 `cn-mee`、国际通用 `qaqi` 等），本项目通过 `selectPrimaryIndex` 优先选取国标指数，确保等级判定与健康建议符合中国环境标准；当国标指数不可用时，回退选择首个具备有效 AQI 数值的指数，最后兜底选择数组首项，形成三级降级保障。第三阶段为污染物提取与单位归一化，通过 `createPollutantMap` 构建 `Map<code, pollutant>`，分别处理必需污染物（缺失补 0）与可选污染物（缺失置空）；同时 `normalizeUnit` 将 QWeather 返回的 Unicode 单位符号（如 μg/m³）映射为 ASCII（ug/m3），保证下游序列化与前端显示的一致性。第四阶段为数据组装，将上述产出合成为最终的 `DashboardSnapshot`，包含 `location`、`air`、`airHourlyForecast`、`forecast` 与 `meta` 五个字段。

#figure(
  kind: image,
  block(width: 100%)[
    #grid(
      columns: (1fr, auto, 1fr, auto, 1fr, auto, 1fr, auto, 1fr),
      column-gutter: 2pt,
      row-gutter: 4pt,
      align: (center + horizon),
      node([*原始响应* \ #text(size: 8pt, gray)[Air / Hourly / Forecast / Geo]], fill: rgb("#dbeafe")),
      arrow(),
      node([*并行解析* \ #text(size: 8pt, gray)[Promise.all \ 各响应结构校验]], fill: rgb("#fef3c7")),
      arrow(),
      node([*AQI 指数选取* \ #text(size: 8pt, gray)[selectPrimaryIndex \ qaqi / cn-mee 优先]], fill: rgb("#fef3c7")),
      arrow(),
      node(
        [*污染物提取 \ + 单位归一化* \ #text(size: 8pt, gray)[createPollutantMap \ normalizeUnit]],
        fill: rgb("#fef3c7"),
      ),
      arrow(),
      node(
        [*DashboardSnapshot* \ #text(size: 8pt, gray)[location + air \ + airHourlyForecast \ + forecast + meta]],
        fill: rgb("#dcfce7"),
      ),
    )
    #v(8pt)
    #align(center)[
      #box(stroke: (dash: "dashed", thickness: 0.5pt), inset: 6pt, radius: 3pt)[
        #text(size: 8.5pt)[
          *fallback 路径*：Geo API 失败 #sym.arrow `resolveLocationFromCoordinates`（6 城市硬编码） #sym.arrow 仍可产出 `location`
        ]
      ]
    ]
  ],
  caption: [QWeather 数据转换流水线图],
) <fig-pipeline>

错误处理策略遵循"必需硬中断、可选软降级"原则。核心空气质量、逐小时预报与天气预报三个端点被定义为必需数据，任一失败即抛出 502 错误直接中断，因为缺失其中任何一项都将导致首页展示不完整，向用户呈现残缺信息不如明确报错。与此相对，Geo 城市解析被定义为可选信号，失败时返回空值并交由 `resolveLocationFromCoordinates` 兜底——该函数维护了一份 6 城市的硬编码坐标映射表，即便 Geo 不可用仍能给出合理的城市归属。这种分层容错设计使系统在多数外部依赖局部故障时仍能降级运行，而非整体不可用。

QWeather 请求 URL 中的经纬度四舍五入到 2 位小数（精度约 1.1 km），这是向 QWeather API 发起请求时的 URL 精度，与缓存 Key 的 4 位小数精度属于不同层面的设计选择。请求 URL 使用 2 位小数可在城市尺度下将地理上相近的请求聚合为同一 QWeather 调用，减少因微小坐标差异导致的重复请求；而缓存 Key 使用 4 位小数则在更精细的街区尺度下保证命中率。整个 QWeather Provider 在缓存层中以 300 秒（5 分钟）的 TTL 写入。

== Mock Provider

`MockWeatherProviderService` 是为本地联调与课程演示设计的降级 Provider，无需任何外部 API 密钥即可运行。其设计核心理念是"确定性"：以经纬度为种子派生所有数据，使相同坐标始终产出相同结果，保证演示与回归测试的可重复性。生成的数据覆盖从"优"到"中度污染"的典型区间，并通过三角函数模拟日内与日间波动，使趋势图表呈现合理曲线而非平直线。Mock Provider 在缓存层中以 120 秒的 TTL 写入，返回值通过 `satisfies DashboardSnapshot` 在编译期保证结构与真实 Provider 完全一致，体现了 Provider 抽象的契约保障价值。

== 逆地理编码

为在界面上向用户展示街道级位置（如"高新路"），系统在 QWeather 城市解析之外，叠加调用 OpenStreetMap Nominatim 服务以补全位置的街道详情字段。Nominatim 是一个免费开源的逆地理编码服务，本项目向其发送经纬度与语言参数获取 JSON 响应。按照 Nominatim 的使用策略要求，请求头中携带自定义 User-Agent，并设置 3 秒超时上限，避免反向解析阻塞主流程。

解析时按道路、街区、小区的优先级从响应中选取最具体的描述字段。所有错误（限频、网络异常、解析失败等）统一返回空值并静默降级；由于街道详情在共享契约中标记为可选字段，缺失不会影响核心数据展示。

== 缓存策略

服务端缓存由 `DashboardCacheService` 提供，使用进程内 Map 存储，每条缓存记录包含过期时间戳与数据快照两个字段。缓存 Key 由经纬度保留四位小数拼接而成。淘汰策略采用懒淘汰——仅在读取时检查过期时间，过期则删除并返回空值，无需额外的定时清理任务。TTL 配置上 QWeather 设为 300 秒，Mock 设为 120 秒。

每次请求时，`DashboardService` 先尝试缓存命中：命中且未过期则直接克隆快照返回，并标记数据来源为缓存；若发现位置详情缺失则额外调用 Nominatim 补全后回写缓存；未命中则走 Provider 路径生成新快照并写入缓存。完整流程如@fig-cache 所示。

缓存层的引入带来了显著的性能与稳定性收益。从性能角度看，一次完整的数据组装需要并行调用 4 至 5 个外部 API，网络延迟叠加第三方服务的响应时间，单次请求的端到端耗时通常在数百毫秒至数秒之间；而缓存命中时，数据直接从进程内 `Map` 读取并克隆返回，响应延迟可降至个位数毫秒级别，两者相差一到两个数量级。从稳定性角度看，缓存将同一坐标的多次外部调用收敛为 TTL 窗口内的首次调用，后续请求均由缓存承接，有效降低了对第三方服务的请求频率，从而减少了触发 API 限频的概率。此外，`meta.cached` 字段将缓存命中状态透传给前端，使 Footer 区域能够区分展示"数据更新于"与"缓存刷新于"两种文案，让用户感知数据的时效性。缓存 Key 采用经纬度四位小数精度，约 11 米的分辨率既足以区分不同街区的查询需求，又能将同一楼宇内多台设备的请求合并为同一条目，在精度与命中率之间取得了合理的平衡。

#figure(
  kind: image,
  block(width: 100%)[
    #set text(size: 9pt)
    #grid(
      columns: (1fr, auto, 1fr, auto, 1fr),
      column-gutter: 4pt,
      align: (center + horizon),
      flow-card([开始], [getDashboard(req)], fill: rgb("#dcfce7"), w: 100%),
      arrow(),
      flow-card([计算缓存键], [lat.toFixed(4):lon.toFixed(4)], w: 100%),
      arrow(),
      flow-card([查询缓存], [检查是否过期], fill: rgb("#fef3c7"), w: 100%),
    )
    #flow-down([命中且未过期？])
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 12pt,
      align: (center + top),
      [
        #align(center)[#text(weight: "bold", size: 8.5pt)[是]]
        #flow-down([])
        #flow-card([克隆快照], [detail 缺失则补全], fill: rgb("#dbeafe"), w: 100%)
        #flow-down([])
        #flow-card([cached = true], [], fill: rgb("#dcfce7"), w: 100%)
      ],
      [
        #align(center)[#text(weight: "bold", size: 8.5pt)[否]]
        #flow-down([])
        #flow-card([Provider 生成快照], [写入缓存（设 TTL）], fill: rgb("#fce7f3"), w: 100%)
        #flow-down([])
        #flow-card([cached = false], [], fill: rgb("#dcfce7"), w: 100%)
      ],
    )
    #flow-down([返回 DashboardResponse])
  ],
  caption: [缓存命中 / 未命中流程图],
) <fig-cache>

== 定位数据获取

前端通过 H5 Geolocation API 获取用户位置：页面加载阶段先以默认城市坐标加载数据，避免用户在授权过程中看到长时间空白；随后异步发起高精度定位请求，授权成功后以真实坐标静默刷新数据，失败时仅输出警告提示，不影响已显示的内容。整个过程不更新 URL 或路由，仅在内存中切换状态，避免页面重渲染抖动。

Android 端的定位则需要跨 H5 与原生层完成授权桥接。当 H5 发起定位请求时，`AirNowWebChromeClient` 拦截该请求并检查 Android 侧是否已获得定位权限。若已授权，直接回调 H5 完成应答；若未授权，则暂存回调引用，通过 Android Runtime Permission 弹窗请求用户授权，待授权结果返回后再将结果回传至 H5 回调，从而让 H5 的定位接口得到正确的授权信号。

除自动定位之外，系统同时提供了纯前端的城市切换能力。城市选择弹窗内置了西安、北京、上海、广州、成都 5 个预置城市，每个城市定义了 `name`、`latitude`、`longitude` 字段；用户点击对应标签后切换城市，数据立即刷新并伴随卡片的渐入动画。当前定位行展示当前选中的城市与坐标，便于用户在多城市之间快速切换查看。

= 结果展示及分析

== 功能展示

围绕课程的三项实验要求，系统在功能与界面上均给出了完整的实现，APP 整体页面布局如@fig-layout 所示。

#figure(
  kind: image,
  block(width: 100%)[
    #set text(size: 9pt)
    #align(center)[
      #box(
        width: 240pt,
        stroke: 1pt + rgb("#475569"),
        radius: 16pt,
        inset: 10pt,
        fill: rgb("#0f172a").lighten(95%),
      )[
        #stack(
          spacing: 6pt,
          box(width: 100%, stroke: (dash: "dashed", thickness: 0.5pt), inset: 6pt, radius: 4pt)[
            #text(size: 7.5pt, gray)[Hero Card] \
            #text(size: 8pt)[当前定位] \
            #text(size: 10pt, weight: "bold")[西安 · 长安区] \
            #text(size: 8pt, gray)[高新路 · 34.1234, 108.8374] \
            #align(end)[#text(size: 8pt)[\[ 城市选择 \]]]
          ],
          box(width: 100%, stroke: (dash: "dashed", thickness: 0.5pt), inset: 6pt, radius: 4pt)[
            #text(size: 7.5pt, gray)[AirQualityCard] \
            #grid(
              columns: (auto, 1fr),
              column-gutter: 8pt,
              align: (left + horizon),
              circle(radius: 18pt, stroke: 4pt + rgb("#fbbf24")),
              [
                #text(size: 8pt)[AQI *92* · 等级：良] \
                #text(size: 7.5pt, gray)[空气质量可以接受……]
              ],
            )
            #v(2pt)
            #line(length: 100%, stroke: 0.4pt + gray)
            #v(2pt)
            #grid(
              columns: 6,
              column-gutter: 1pt,
              align: center,
              text(size: 7pt)[PM2.5\ *42*],
              text(size: 7pt)[PM10\ *78*],
              text(size: 7pt)[SO#sub[2]\ *8*],
              text(size: 7pt)[NO#sub[2]\ *25*],
              text(size: 7pt)[O#sub[3]\ *89*],
              text(size: 7pt)[CO\ *0.7*],
            )
          ],
          box(width: 100%, stroke: (dash: "dashed", thickness: 0.5pt), inset: 6pt, radius: 4pt)[
            #text(size: 7.5pt, gray)[HourlyAirForecastCard] \
            #text(size: 7.5pt)[当前 92 · 峰值 110 · 低点 68] \
            #v(2pt)
            #box(width: 100%, height: 30pt, stroke: 0.3pt + gray, inset: 2pt)[
              #place(bottom + left)[
                #polyline(
                  stroke: 1.5pt + rgb("#f59e0b"),
                  (0pt, 18pt),
                  (20pt, 12pt),
                  (40pt, 8pt),
                  (60pt, 14pt),
                  (80pt, 6pt),
                  (100pt, 16pt),
                  (120pt, 10pt),
                  (140pt, 14pt),
                  (160pt, 4pt),
                  (180pt, 12pt),
                  (200pt, 18pt),
                )
              ]
            ]
          ],
          box(width: 100%, stroke: (dash: "dashed", thickness: 0.5pt), inset: 6pt, radius: 4pt)[
            #text(size: 7.5pt, gray)[ForecastChart] \
            #text(size: 7.5pt)[温度趋势] \
            #box(width: 100%, height: 26pt, stroke: 0.3pt + gray, inset: 2pt)[
              #place(bottom + left)[
                #polyline(
                  stroke: 1.4pt + rgb("#fb923c"),
                  (0pt, 6pt),
                  (40pt, 10pt),
                  (80pt, 4pt),
                  (120pt, 8pt),
                  (160pt, 10pt),
                  (200pt, 6pt),
                )
                #polyline(
                  stroke: 1.4pt + rgb("#38bdf8"),
                  (0pt, 18pt),
                  (40pt, 16pt),
                  (80pt, 20pt),
                  (120pt, 14pt),
                  (160pt, 18pt),
                  (200pt, 22pt),
                )
              ]
            ]
            #v(2pt)
            #text(size: 7.5pt)[湿度趋势] \
            #box(width: 100%, height: 20pt, stroke: 0.3pt + gray, inset: 2pt)[
              #place(bottom + left)[
                #polyline(
                  stroke: 1.4pt + rgb("#34d399"),
                  (0pt, 14pt),
                  (40pt, 10pt),
                  (80pt, 6pt),
                  (120pt, 12pt),
                  (160pt, 8pt),
                  (200pt, 10pt),
                )
              ]
            ]
            #v(2pt)
            #text(size: 7pt)[05-04  26°/15°  62%   05-05  25°/14°  60%]
          ],
          box(width: 100%, stroke: (dash: "dashed", thickness: 0.5pt), inset: 4pt, radius: 4pt)[
            #text(size: 7pt, gray)[qweather · cached=false · 刷新于 2026/5/4 12:00:00]
          ],
        )
      ]
    ]
    #v(4pt)
    #align(center)[
      #text(size: 8.5pt, gray)[
        竖屏 9:19.5 线框图：自上而下依次为定位卡片 / AirQualityCard / HourlyAirForecastCard / ForecastChart / Footer
      ]
    ]
  ],
  caption: [APP 界面布局总览图],
) <fig-layout>

*定位功能*方面，页面打开即以默认坐标（西安）加载数据，定位卡片顶部展示"当前定位"标签与城市/区县名，例如"西安 · 长安区"，下方以小字显示由 Nominatim 提供的街道级 detail（例如"高新路"）以及当前坐标。若用户授权浏览器或 Android 定位，App 会自动以真实坐标重新加载并切换显示文案。城市选择弹窗中提供 5 个预置城市，选中后以蓝色边框 + 背景色高亮，数据随之即时刷新。在服务端持久化方面，前端将经纬度通过 `POST /api/dashboard` 传入后端，后端通过 QWeather Geo 接口与 Nominatim 共同解析出城市名、区县名与街道详情，将完整的定位信息连同空气质量数据一起组装为 `DashboardSnapshot`，写入缓存并以 TTL 管理——定位城市及其关联数据持久存在于服务端缓存中，客户端仅消费已解析的定位结果，无需自行调用任何地理编码服务。

*界面设计*方面，整体采用暗色毛玻璃风格（`color-scheme: dark`、`backdrop-filter: blur(20px)`），背景叠加蓝色光晕、粉色光晕与深海军蓝的渐变。AQI 环形进度通过 `conic-gradient` 绘制，颜色随 AQI 等级（绿/黄/粉/橙）动态切换，数值在 1100ms 内以 `easeOutCubic` 缓动平滑计数，颜色同步过渡。六项污染物以六列网格呈现 PM2.5、PM10、SO#sub[2]、NO#sub[2]、O#sub[3]、CO 的浓度与单位，并按 `--metric-index * 45ms` 实现交错入场。24 小时 AQI 趋势图以自绘 SVG 实现单一折线，技术规格如@fig-hourly-spec 所示；多日天气 Card 中包含温度双折线图（最高温+最低温）与独立的湿度折线图，两者上下排列共享同一 X 轴日期，技术规格如@fig-forecast-spec 所示，下方天气详情条则以列表形式呈现每日日期、温度范围与湿度。交互层面提供定位卡片点击刷新（伴随 `cursor: wait` 状态切换）、城市选择弹窗的 `Transition` 动画、滚动渐入（`IntersectionObserver` + `data-reveal`）以及加载态脉冲圆点动画；无障碍方面则覆盖 `aria-busy`、`aria-expanded`、`role="button"`、SVG 的 `aria-label`、`focus-visible` 与 `prefers-reduced-motion` 等标准。

#figure(
  kind: image,
  block(width: 100%)[
    #align(center)[
      #box(width: 320pt, height: 130pt, stroke: 0.4pt + gray, fill: rgb("#0f172a").lighten(96%), inset: 0pt)[
        #place(top + left, dx: 32pt, dy: 24pt)[#line(length: 276pt, stroke: (
          dash: "dotted",
          thickness: 0.4pt,
          paint: gray,
        ))]
        #place(top + left, dx: 32pt, dy: 49pt)[#line(length: 276pt, stroke: (
          dash: "dotted",
          thickness: 0.4pt,
          paint: gray,
        ))]
        #place(top + left, dx: 32pt, dy: 74pt)[#line(length: 276pt, stroke: (
          dash: "dotted",
          thickness: 0.4pt,
          paint: gray,
        ))]
        #place(top + left, dx: 32pt, dy: 94pt)[#line(length: 276pt, stroke: 0.6pt + gray)]
        #place(top + left, dx: 32pt, dy: 24pt)[
          #polyline(
            stroke: (paint: rgb("#f59e0b"), thickness: 2pt, cap: "round"),
            (0pt, 50pt),
            (23pt, 42pt),
            (46pt, 36pt),
            (69pt, 44pt),
            (92pt, 30pt),
            (115pt, 22pt),
            (138pt, 28pt),
            (161pt, 38pt),
            (184pt, 48pt),
            (207pt, 56pt),
            (230pt, 46pt),
            (253pt, 38pt),
          )
        ]
        #place(top + left, dx: 30pt, dy: 72pt)[#circle(radius: 2pt, fill: rgb("#f59e0b"), stroke: 0.5pt + black)]
        #place(top + left, dx: 122pt, dy: 52pt)[#circle(radius: 2pt, fill: rgb("#f59e0b"), stroke: 0.5pt + black)]
        #place(top + left, dx: 214pt, dy: 78pt)[#circle(radius: 2pt, fill: rgb("#f59e0b"), stroke: 0.5pt + black)]
        #place(top + left, dx: 283pt, dy: 62pt)[#circle(radius: 2pt, fill: rgb("#f59e0b"), stroke: 0.5pt + black)]
        #place(top + left, dx: 4pt, dy: 20pt)[#text(size: 7pt, gray)[110]]
        #place(top + left, dx: 4pt, dy: 45pt)[#text(size: 7pt, gray)[ 90]]
        #place(top + left, dx: 4pt, dy: 70pt)[#text(size: 7pt, gray)[ 70]]
        #place(top + left, dx: 4pt, dy: 90pt)[#text(size: 7pt, gray)[ 50]]
        #place(top + left, dx: 24pt, dy: 100pt)[#text(size: 7pt, gray)[00:00]]
        #place(top + left, dx: 116pt, dy: 100pt)[#text(size: 7pt, gray)[08:00]]
        #place(top + left, dx: 208pt, dy: 100pt)[#text(size: 7pt, gray)[16:00]]
        #place(top + left, dx: 277pt, dy: 100pt)[#text(size: 7pt, gray)[24:00]]
        #place(top + left, dx: 25pt, dy: 60pt)[#text(size: 7pt, weight: "bold")[68]]
        #place(top + left, dx: 117pt, dy: 40pt)[#text(size: 7pt, weight: "bold")[110]]
        #place(top + left, dx: 209pt, dy: 66pt)[#text(size: 7pt, weight: "bold")[78]]
        #place(top + left, dx: 278pt, dy: 50pt)[#text(size: 7pt, weight: "bold")[92]]
        #place(top + right, dx: -10pt, dy: 4pt)[
          #box(stroke: 0.4pt + gray, inset: (x: 4pt, y: 1pt), radius: 6pt)[#text(size: 6.5pt)[当前 92]]
          #h(2pt)
          #box(stroke: 0.4pt + gray, inset: (x: 4pt, y: 1pt), radius: 6pt)[#text(size: 6.5pt)[峰值 110]]
          #h(2pt)
          #box(stroke: 0.4pt + gray, inset: (x: 4pt, y: 1pt), radius: 6pt)[#text(size: 6.5pt)[低点 68]]
        ]
      ]
    ]
    #v(4pt)
    #align(center)[
      #text(size: 8pt, gray)[
        viewBox `0 0 320 212` ；padding：left=32 / right=12 / top=24 / bottom=36 ；折线 `#f59e0b`，线宽 3，round caps ；
        点 r=4.5 ；标签每 4 点 + 末点 ；Y 轴 `chartBounds = { min: max(0, rawMin - buffer), max: rawMax + buffer }`，`buffer = max(3, spread * 0.16)`
      ]
    ]
  ],
  caption: [24h AQI 趋势图技术规格图],
) <fig-hourly-spec>

#figure(
  kind: image,
  block(width: 100%)[
    #align(center)[
      #box(width: 320pt, height: 130pt, stroke: 0.4pt + gray, fill: rgb("#0f172a").lighten(96%), inset: 0pt)[
        #place(top + left, dx: 36pt, dy: 24pt)[#line(length: 266pt, stroke: (
          dash: "dotted",
          thickness: 0.4pt,
          paint: gray,
        ))]
        #place(top + left, dx: 36pt, dy: 49pt)[#line(length: 266pt, stroke: (
          dash: "dotted",
          thickness: 0.4pt,
          paint: gray,
        ))]
        #place(top + left, dx: 36pt, dy: 74pt)[#line(length: 266pt, stroke: (
          dash: "dotted",
          thickness: 0.4pt,
          paint: gray,
        ))]
        #place(top + left, dx: 36pt, dy: 94pt)[#line(length: 266pt, stroke: 0.6pt + gray)]
        #place(top + left, dx: 36pt, dy: 24pt)[
          #polyline(
            stroke: (paint: rgb("#fb923c"), thickness: 2pt, cap: "round"),
            (0pt, 24pt),
            (53pt, 18pt),
            (106pt, 10pt),
            (159pt, 14pt),
            (212pt, 22pt),
            (265pt, 16pt),
          )
        ]
        #place(top + left, dx: 36pt, dy: 24pt)[
          #polyline(
            stroke: (paint: rgb("#38bdf8"), thickness: 2pt, cap: "round"),
            (0pt, 56pt),
            (53pt, 50pt),
            (106pt, 46pt),
            (159pt, 52pt),
            (212pt, 60pt),
            (265pt, 54pt),
          )
        ]
        #place(top + left, dx: 4pt, dy: 20pt)[#text(size: 7pt, gray)[28°]]
        #place(top + left, dx: 4pt, dy: 45pt)[#text(size: 7pt, gray)[24°]]
        #place(top + left, dx: 4pt, dy: 70pt)[#text(size: 7pt, gray)[18°]]
        #place(top + left, dx: 4pt, dy: 90pt)[#text(size: 7pt, gray)[12°]]
        #place(top + left, dx: 28pt, dy: 100pt)[#text(size: 7pt, gray)[05-04]]
        #place(top + left, dx: 81pt, dy: 100pt)[#text(size: 7pt, gray)[05-05]]
        #place(top + left, dx: 134pt, dy: 100pt)[#text(size: 7pt, gray)[05-06]]
        #place(top + left, dx: 187pt, dy: 100pt)[#text(size: 7pt, gray)[05-07]]
        #place(top + left, dx: 240pt, dy: 100pt)[#text(size: 7pt, gray)[05-08]]
        #place(top + left, dx: 293pt, dy: 100pt)[#text(size: 7pt, gray)[05-09]]
        #place(top + right, dx: -8pt, dy: 4pt)[
          #box(stroke: 0.4pt + gray, inset: (x: 4pt, y: 1pt), radius: 6pt)[
            #text(size: 6.5pt, fill: rgb("#fb923c"))[● 最高温]
            #h(4pt)
            #text(size: 6.5pt, fill: rgb("#38bdf8"))[● 最低温]
          ]
        ]
      ]
    ]
    #v(6pt)
    #align(center)[
      #box(width: 320pt, height: 130pt, stroke: 0.4pt + gray, fill: rgb("#0f172a").lighten(96%), inset: 0pt)[
        #place(top + left, dx: 36pt, dy: 24pt)[#line(length: 266pt, stroke: (
          dash: "dotted",
          thickness: 0.4pt,
          paint: gray,
        ))]
        #place(top + left, dx: 36pt, dy: 49pt)[#line(length: 266pt, stroke: (
          dash: "dotted",
          thickness: 0.4pt,
          paint: gray,
        ))]
        #place(top + left, dx: 36pt, dy: 74pt)[#line(length: 266pt, stroke: (
          dash: "dotted",
          thickness: 0.4pt,
          paint: gray,
        ))]
        #place(top + left, dx: 36pt, dy: 94pt)[#line(length: 266pt, stroke: 0.6pt + gray)]
        #place(top + left, dx: 36pt, dy: 24pt)[
          #polyline(
            stroke: (paint: rgb("#34d399"), thickness: 2pt, cap: "round"),
            (0pt, 46pt),
            (53pt, 40pt),
            (106pt, 34pt),
            (159pt, 38pt),
            (212pt, 44pt),
            (265pt, 36pt),
          )
        ]
        #place(top + left, dx: 4pt, dy: 20pt)[#text(size: 7pt, gray)[90%]]
        #place(top + left, dx: 4pt, dy: 45pt)[#text(size: 7pt, gray)[70%]]
        #place(top + left, dx: 4pt, dy: 70pt)[#text(size: 7pt, gray)[50%]]
        #place(top + left, dx: 4pt, dy: 90pt)[#text(size: 7pt, gray)[30%]]
        #place(top + left, dx: 28pt, dy: 100pt)[#text(size: 7pt, gray)[05-04]]
        #place(top + left, dx: 81pt, dy: 100pt)[#text(size: 7pt, gray)[05-05]]
        #place(top + left, dx: 134pt, dy: 100pt)[#text(size: 7pt, gray)[05-06]]
        #place(top + left, dx: 187pt, dy: 100pt)[#text(size: 7pt, gray)[05-07]]
        #place(top + left, dx: 240pt, dy: 100pt)[#text(size: 7pt, gray)[05-08]]
        #place(top + left, dx: 293pt, dy: 100pt)[#text(size: 7pt, gray)[05-09]]
        #place(top + right, dx: -8pt, dy: 4pt)[
          #box(stroke: 0.4pt + gray, inset: (x: 4pt, y: 1pt), radius: 6pt)[
            #text(size: 6.5pt, fill: rgb("#34d399"))[● 湿度]
          ]
        ]
      ]
    ]
    #v(4pt)
    #align(center)[
      #text(size: 8pt, gray)[
        上方温度图：viewBox `0 0 320 196`，橙色高温 `#fb923c`、蓝色低温 `#38bdf8`，线宽 3，round caps ；点 r=4.5，高温标签 `y - 10`、低温标签 `y + 16`，均带 `°` 后缀
      ]
    ]
    #align(center)[
      #text(size: 8pt, gray)[
        下方湿度图：同尺寸与 padding，绿色 `#34d399`，线宽 3 ；Y 轴 0%\~100%，标签带 `%` 后缀 ；底部 forecast-strip 每日含日期 / 温度范围 / 湿度，按 `--forecast-index * 60ms` 交错入场
      ]
    ]
  ],
  caption: [多日天气趋势图技术规格图],
) <fig-forecast-spec>

*天气详情与空气质量指数*方面，AQI 数值、等级文字（优 / 良 / 轻度污染 / 中度污染）与对应的健康建议文案均实时呈现于 `AirQualityCard` 中（如"空气质量很好，适合户外活动"）；六项污染物逐项浓度展示，颗粒物使用 `ug/m3` 单位、CO 使用 `mg/m3` 单位。24 小时逐小时 AQI 预报通过 `HourlyAirForecastCard` 展现 AQI 走向并允许污染物逐小时值为 `null`；多日预报涵盖未来 6 天的最高温、最低温与湿度。所有数据均来源于和风天气 API，由后端聚合后以 `DashboardResponse` 统一返回，前端组件直接消费业务模型。

== 上机测试与运行效果

在功能实现层面，系统三端均完成构建并通过上机验证：后端 NestJS 项目编译无错，`pnpm build` 成功产出部署产物，服务启动后 `GET /health` 返回正常；前端 Vite 项目构建通过，H5 页面在 Chrome 移动端模拟器中加载正常，AQI 数据拉取、环形进度动画、SVG 折线图渲染、城市切换与定位刷新等交互功能均按预期工作；Android 项目 `gradlew assembleDebug` 构建成功，APK 安装至模拟器后 WebView 正常加载 H5 页面，定位权限桥接流程走通，H5 获得真实坐标并刷新数据。以下 4 张实机截图依次展示了首页完整界面、AQI 详情卡片、多日天气趋势图（含温度与湿度折线）以及城市切换弹窗，覆盖了课程三项实验要求的核心功能点。

#figure(
  kind: image,
  grid(
    columns: (1fr, 1fr, 1fr, 1fr),
    column-gutter: 10pt,
    align: center + bottom,
    [
      #image("figures/home.jpg", width: 100%)
      #v(2pt)
      #text(size: 8pt, gray)[首页完整界面]
    ],
    [
      #image("figures/aqi.jpg", width: 100%)
      #v(2pt)
      #text(size: 8pt, gray)[AQI 详情卡片]
    ],
    [
      #image("figures/trend.jpg", width: 100%)
      #v(2pt)
      #text(size: 8pt, gray)[多日天气趋势图]
    ],
    [
      #image("figures/location.jpg", width: 100%)
      #v(2pt)
      #text(size: 8pt, gray)[城市切换弹窗]
    ],
  ),
  caption: [实机运行截图],
) <fig-screenshots>

== 结果分析

在实际运行验证中，Provider 抽象的设计目标得到了完整兑现。QWeather Provider 返回真实监测数据（实时 AQI、污染物浓度、和风官方建议），前端界面的组件结构、动画节奏、交互行为均基于统一的 `DashboardSnapshot` 契约渲染，与数据来源无关——切换数据源仅需在服务端修改环境变量，前端代码零改动。这对应了"开闭原则"在项目中的真实落地：数据供给层的变更不会波及消费层，后端新增 Provider 实现也无需触碰任何前端逻辑。

缓存机制对请求效率的提升同样显著。首次请求需要并行调用 4 至 5 个外部 API，整体响应时间受第三方网络与服务质量影响；后续在 TTL 内的请求直接从进程内 `Map` 返回，几乎不消耗外部资源，响应延迟从秒级降至毫秒级。`meta.cached` 字段还让前端可感知数据来源，从而在 Footer 区域区分展示"缓存更新于"与"刷新于"两种文案，让用户对数据时效性有直观判断。缓存 Key 采用 4 位小数精度（约 11 米），既足以区分不同街区的查询需求，又能将同一楼宇内多台设备的请求合并为同一条目，在精度与命中率之间取得了合理的平衡。

从空气质量数据的实际分布中，可以观察到明显的日内规律。以西安为例，早晚高峰时段 AQI 普遍偏高（约 90\~120），午间则相对偏低（约 60\~80），这一规律与城市交通排放和大气扩散条件的日变化一致。用户可据此安排出行——选择 AQI 低点时段进行户外活动，避开 AQI 峰值时段长时间停留。配合多日温度与湿度趋势可以进一步研判扩散条件：低温高湿天气下污染物不易扩散，AQI 容易上升，提示用户提前做好防护。从实机截图中可以直观看到，24 小时 AQI 趋势折线图清晰呈现了这一日内波动规律，而多日天气趋势图中温度双折线与湿度折线的独立展示则让用户能够同时把握气温变化与湿度走向，综合判断污染物扩散条件。

界面动效与交互设计对信息传达的有效性也得到了验证。AQI 环形进度以颜色与弧度同步变化传递等级切换，数值计数动画使数字变化过程可感知而非瞬间跳变，避免了用户对数据是否刷新的困惑。卡片滚动渐入与污染物面板交错入场形成自上而下的视觉节奏，引导用户按定位到 AQI 再到趋势的优先级逐层阅读。城市切换弹窗的 Transition 动画使状态切换过程平滑可预期，降低了操作突兀感。这些动效并非纯粹的装饰，而是将数据的时效性变化与界面的状态转换可视化，帮助用户建立对"数据刚刚更新"的直觉感知。从无障碍设计的角度看，`aria-busy`、`aria-expanded`、`role="button"`、SVG 的 `aria-label`、`focus-visible` 与 `prefers-reduced-motion` 等属性的覆盖，也使得系统在辅助技术环境下具备基本的可访问性。

从三端协同的角度审视，系统的数据流路径完整且闭环：前端 H5 通过 `POST /api/dashboard` 发起请求，后端以缓存优先策略组装 `DashboardResponse`，前端组件直接消费业务模型渲染界面；Android WebView 宿主通过跨层权限桥接打通了定位链路，使得原生能力与 Web 业务逻辑无缝衔接。共享契约包 `@airnow/shared` 在编译期同步前后端类型，从根本上杜绝了字段漂移问题。整条链路从数据获取、缓存管理、类型契约到界面渲染，各层职责清晰、边界分明，体现了模块化架构在全栈项目中的实际价值。

== 不足与改进方向

本系统在功能实现上已基本达成设计目标，但仍存在以下三方面不足。第一，单实例部署的吞吐上限：当前系统采用单进程运行，内存级缓存仅在进程内有效，多实例部署时各实例缓存独立，会导致重复对外请求与数据短时间内不一致。第二，同步阻塞的 Provider 调用模式：高并发场景下大量请求会同时打到第三方 API，容易触发供应商的限频策略，缺乏请求排队与速率控制机制。第三，单数据源的可用性风险：仅接入 QWeather 一个真实数据源，一旦其服务中断或额度耗尽，系统便只能依赖 Mock 演示模式，不能真正提供线上服务。

= 心得与体会

== 项目收获

Monorepo 架构是本次项目中最先感受到红利的决策。pnpm workspace 让前端、后端与共享类型包在同一仓库内协同开发，`packages/shared` 集中维护跨端契约，任何一方修改接口定义后另一方在编译期即可感知。这种组织方式在项目中期的一次大规模接口重构中体现得尤为明显——当我们将 `DashboardSnapshot` 的 `air` 字段从扁平结构改为嵌套结构时，前端所有消费该字段的组件在编译时立即收到类型错误提示，逐一修复后即可保证运行时不会出现字段访问异常。在传统的多仓库架构下，这类重构往往需要两端开发者手动同步接口文档，再通过联调阶段发现遗漏，耗时且易出错。

Provider 抽象模式让团队切身体会到面向接口编程与依赖注入的实际价值。开闭原则在教科书中是抽象概念，而在本项目中则体现为切换数据源仅需修改一行环境变量配置——前端代码零改动，后端业务逻辑零改动，仅 `DashboardModule` 中的 `useFactory` 函数根据配置选择不同的实现。这种解耦还带来了一个意料之外的好处：在 API 配额耗尽或网络受限的演示场景下，切换到 Mock Provider 即可保证演示链路完整可用，无需临时修改代码或降级功能。

前后端契约驱动开发是本项目在工程实践上最有价值的探索之一。将所有共享类型集中到 `@airnow/shared` 包中，前后端通过 `import type` 引入同一份类型源，TypeScript 编译器在编译期即可保证接口一致性。项目初期曾出现过前端期望 `pollutants.pm25` 为 `number` 而后端实际返回 `string` 的情况，这类问题在传统开发模式下往往要到联调阶段才会暴露，而在契约驱动模式下，任何一方修改字段类型后另一方在下次编译时立即收到错误提示，将集成问题从"运行时发现"前置到"编译期暴露"。

跨平台协作的实践让团队理解了 Web 技术在移动端的分发优势与原生能力桥接的必要性。Android 端仅作为极简的 WebView 宿主，不承担任何原生业务逻辑，所有 UI 与数据交互均由远端 H5 完成。这种架构以最小的原生代价获得了最大的跨端覆盖——业务逻辑集中在 Web 与 Server，Android 端的核心工作量仅在于 WebView 初始化与定位权限桥接。从维护成本的角度看，后续若需调整界面布局或新增功能，只需修改 H5 代码并重新部署，无需重新构建和分发 APK。

自绘 SVG 图表的实践加深了团队对数据可视化的底层理解。摒弃 ECharts 等第三方库，转而完全手写 SVG 坐标系、数据映射、padding 计算与响应式布局，虽然初期投入较大，但换来了对每一个像素的精确控制。暗色毛玻璃风格的卡片化布局要求图表与背景深度融合，自绘方案使我们能够直接操作 SVG 元素的 `stroke`、`fill`、`opacity` 等属性，与 CSS 变量和 `backdrop-filter` 协同工作，避免了第三方库引入的主题适配负担。最终产出的 AQI 环形进度、24 小时折线图、温度双折线图与湿度折线图均为纯 SVG 实现，打包体积零依赖增量。

此外，项目中对缓存策略、错误分层容错、懒淘汰机制等后端工程实践的探索，也让我们对服务端架构的权衡有了更直观的认识。缓存 Key 的精度选择（4 位小数，约 11 米）、TTL 的取值（QWeather 300 秒、Mock 120 秒）、必需数据与可选数据的差异化错误处理，这些看似细小的设计决策在实际运行中共同决定了系统的响应速度与容错能力。这些经验对于后续参与更大规模的全栈项目具有直接的参考价值。

== 遇到的困难与解决

第一个困难是 WebView 中定位权限的跨层协作。H5 通过 `navigator.geolocation` 发起请求，但浏览器层无法直接获取 Android 原生权限，单独依赖任一侧都无法走通完整流程。我们在 `AirNowWebChromeClient.onGeolocationPermissionsShowPrompt` 中拦截 H5 请求，引入 `pendingGeolocationCallback` 暂存机制——保存 `callback` 与 `origin`，再通过 `locationPermissionLauncher` 触发 Android Runtime Permission 请求，授权结果通过 `ActivityResultCallback` 回到原生侧后再 `invoke` 回 H5 callback，从而打通了跨层授权链路，让 H5 在 WebView 中也能正常获取定位。

第二个困难是第三方 API 响应结构的不稳定。QWeather 不同端点的响应结构差异较大：空气质量接口使用嵌套数组，天气预报使用相对扁平的字段；某些城市某些时段还会缺失部分字段（如个别污染物为空）。我们在 Provider 层做了多层数据转换与容错：`selectPrimaryIndex` 采用多级回退策略选取主 AQI 指数；`getOptionalConcentration` 在缺失时返回 `null` 而非抛错；`normalizeUnit` 统一各端点的单位字符；同时所有可选数据失败均静默降级，确保下游始终收到结构稳定的 `DashboardSnapshot`。

第三个困难是前后端的类型同步。在前后端独立开发的初期阶段，曾出现过例如 `pollutants.pm25` 前端期望 `number` 而后端实际返回 `string` 的情况，运行时才被发现。我们抽取了 `@airnow/shared` 共享类型包，前后端通过 `import type` 引入同一份类型源，TypeScript 编译期即可发现接口偏差——任何一方修改字段后，另一方在下次编译时立即得到错误提示，从根本上杜绝了字段类型漂移问题。

== 未来展望

针对上述不足，后续改进可从架构与产品两个层面推进。架构层面，引入分布式缓存（如 Redis）与消息队列（如 RabbitMQ），让多实例共享缓存层并实现 Provider 请求的异步化削峰，从而支撑更大规模的部署；同时在现有 `DashboardWeatherProvider` 接口基础上引入多 Provider 自动 fallback 机制，主数据源失败时自动切换备用数据源，提升可用性。产品层面，可增加用户偏好（常用城市、AQI 通知阈值）与历史查询能力，引入持久化存储（数据库），让系统从单纯的"工具型"逐步演进为具备账户与历史数据的"服务型"应用；同时在 Android 端补齐品牌图标、离线页与启动页等细节，进一步打磨整体体验。
