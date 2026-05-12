# AirNow

Air quality monitoring monorepo — AQI, pollutants, 24h trends, weather forecast.

## Repo Structure

```
apps/web/          Vue 3 + Vite (mobile-first, TypeScript)
apps/server/       NestJS API (TypeScript)
apps/android/      Kotlin WebView host (loads remote H5)
packages/shared/   Shared type contracts (.d.ts only, no runtime code)
report/            Course project report (Typst), not part of the app
```

`packages/shared` exports pure TypeScript declarations consumed by both `apps/web` and `apps/server` via `"workspace:*"` dependency. Changes to shared types affect both ends.

## Commands

```bash
pnpm install          # install all
pnpm dev              # run server + web concurrently
pnpm dev:web          # web only (localhost:5173)
pnpm dev:server       # server only (localhost:3000)
pnpm build            # build all packages
pnpm typecheck        # typecheck all packages
```

Per-package typecheck:
```bash
pnpm --filter @airnow/server typecheck
pnpm --filter @airnow/web typecheck
pnpm --filter @airnow/shared typecheck
```

Server build uses separate `tsconfig.build.json` (excludes `.spec.ts`). Web build runs `vue-tsc --noEmit && vite build`.

## Key Conventions

- **No tests, no linter, no formatter, no CI** — verify changes manually via `pnpm dev`
- **No runtime code in shared** — `packages/shared/src/` contains only `.d.ts` type declarations
- **TypeScript 6.x** across all packages
- **Server dev uses `tsx watch`** (not `ts-node` or `swc`)
- **Server env** loaded via Node's native `loadEnvFile` from `apps/server/.env` (see `.env.example`)
- **Web env** via Vite's standard `VITE_*` mechanism (see `apps/web/.env.example`)
- **Provider pattern**: `WEATHER_PROVIDER` env var selects between `qweather` and `mock`. Mock works offline with no keys. Provider is injected via NestJS DI using a Symbol token (`WEATHER_PROVIDER` in `dashboard.tokens.ts`)
- **Cache**: In-memory `Map`, key = `latitude.toFixed(4):longitude.toFixed(4)`. QWeather TTL = 300s, Mock TTL = 120s
- **Default city**: Xi'an (西安) — coordinates hardcoded in `useDashboard.ts` and `App.vue`
- **No database** — all data from external API or mock, cached in process memory
- **Web uses `fetch` directly** — no axios on the frontend; server uses axios for external API calls
- **Dark theme UI** — custom CSS, no CSS framework, hand-drawn SVG charts

## Architecture Notes

- Single API endpoint: `POST /api/dashboard` (latitude/longitude → full dashboard snapshot)
- Health check: `GET /api/health`
- Server uses `ValidationPipe` with `whitelist` + `forbidNonWhitelisted` — extra fields in request body return 400
- Server sets global prefix `/api` via config (overridable with `API_PREFIX` env var)
- Nominatim reverse geocoding runs on every dashboard request (cached result enriched with `detail` field)
- Frontend auto-retries once after 1s if `location.detail` is missing (Nominatim rate limit fallback)
- All UI charts are hand-drawn SVG (no ECharts or chart library)
- Android WebView 入口 URL 配置在 `local.properties`（通过 `BuildConfig.WEB_URL` 注入）；要修改入口地址，编辑 `apps/android/local.properties` 中的 `APP_DOMAIN`

### QWeather API endpoints (when `WEATHER_PROVIDER=qweather`)

| Endpoint | Purpose |
|----------|---------|
| `/airquality/v1/current/{lat}/{lon}` | Current AQI + pollutants |
| `/airquality/v1/hourly/{lat}/{lon}` | 24h hourly AQI forecast |
| `/v7/weather/7d?location={lon},{lat}` | 7-day weather forecast |
| `/geo/v2/city/lookup?location={lon},{lat}` | City name resolution |

Auth: `X-QW-Api-Key` header. All 4 requests run in parallel via `Promise.all`.

### Location resolution fallback

If QWeather geo lookup fails, server falls back to `location-resolver.ts` — a static nearest-city matcher against 6 hardcoded Chinese city profiles.

## Android Build

```bash
cd apps/android
ANDROID_HOME=$HOME/lib/android ./gradlew assembleDebug --no-daemon
```

Requires JDK 17 (`compileOptions` target = Java 17). APK output: `app/build/outputs/apk/debug/app-debug.apk`. Package: configured via `local.properties` (`APP_PACKAGE`). `minSdk=24`, `targetSdk=34`.

## File Map (non-obvious)

- `apps/server/src/config.ts` — server config factory, loads `.env` at import time
- `apps/web/config.ts` — web config factory (not a Vite plugin, plain function)
- `apps/web/vite.config.ts` — uses `config.ts` for proxy and host settings
- `apps/server/src/modules/dashboard/dashboard.tokens.ts` — DI symbol for provider injection
- `apps/server/src/modules/dashboard/dashboard.types.ts` — re-exports from `@airnow/shared` + `DashboardWeatherProvider` interface
- `apps/server/src/modules/dashboard/location-resolver.ts` — static city fallback (6 profiles)
- `apps/server/docs/dashboard.http` / `health.http` — HTTP request files for manual testing
- `playground/` — gitignored scratch area, not part of the build
