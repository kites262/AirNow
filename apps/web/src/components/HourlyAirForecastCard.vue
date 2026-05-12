<script setup lang="ts">
import { computed } from "vue";
import type { DashboardAirHourlyForecast } from "@airnow/shared";

const props = defineProps<{
  forecast: DashboardAirHourlyForecast;
}>();

const width = 320;
const height = 212;
const paddingLeft = 32;
const paddingRight = 12;
const paddingTop = 24;
const paddingBottom = 36;
const yAxisTickCount = 4;
const usableWidth = width - paddingLeft - paddingRight;
const usableHeight = height - paddingTop - paddingBottom;

const metricValues = computed(() =>
  props.forecast.hours.map((hour) => hour.aqi),
);

const chartBounds = computed(() => {
  if (!metricValues.value.length) {
    return { min: 0, max: 10 };
  }

  const rawMin = Math.min(...metricValues.value);
  const rawMax = Math.max(...metricValues.value);
  const spread = Math.max(rawMax - rawMin, 8);
  const buffer = Math.max(3, spread * 0.16);

  return {
    min: Math.max(0, rawMin - buffer),
    max: rawMax + buffer,
  };
});

const summary = computed(() => {
  const values = metricValues.value;

  if (values.length === 0) {
    return {
      latest: "0",
      max: "0",
      min: "0",
    };
  }

  return {
    latest: formatMetricValue(values[0] ?? 0),
    max: formatMetricValue(Math.max(...values)),
    min: formatMetricValue(Math.min(...values)),
  };
});

function formatMetricValue(value: number) {
  return `${Math.round(value)}`;
}

function getX(index: number) {
  return paddingLeft
    + (usableWidth / Math.max(props.forecast.hours.length - 1, 1)) * index;
}

function getY(value: number) {
  const { min, max } = chartBounds.value;
  const normalized = (value - min) / Math.max(max - min, 1);
  return height - paddingBottom - normalized * usableHeight;
}

function formatHourLabel(forecastTime: string) {
  return new Date(forecastTime).toLocaleTimeString("zh-CN", {
    hour: "2-digit",
  });
}

const linePoints = computed(() =>
  props.forecast.hours
    .map((hour, index) => {
      const x = getX(index);
      const y = getY(hour.aqi);
      return `${x},${y}`;
    })
    .join(" "),
);

const chartPoints = computed(() =>
  props.forecast.hours.map((hour, index) => {
    const value = hour.aqi;
    const x = getX(index);
    const y = getY(value);

    return {
      key: hour.forecastTime,
      x,
      y,
      valueLabel: formatMetricValue(value),
      labelY: Math.max(y - 10, paddingTop - 2),
      timeLabel: formatHourLabel(hour.forecastTime),
      showTick: index % 4 === 0 || index === props.forecast.hours.length - 1,
      showValue: index % 4 === 0 || index === props.forecast.hours.length - 1,
    };
  }),
);

const yAxisTicks = computed(() => {
  const { min, max } = chartBounds.value;
  const step = (max - min) / Math.max(yAxisTickCount - 1, 1);

  return Array.from({ length: yAxisTickCount }, (_, index) => {
    const value = max - step * index;
    const y = getY(value);

    return {
      key: `${index}-${value}`,
      valueLabel: formatMetricValue(value),
      y,
    };
  });
});
</script>

<template>
  <section class="panel air-hourly-card">
    <div class="section-heading forecast-heading">
      <div>
        <p class="eyebrow">空气预报</p>
        <h3>未来24小时 AQI 趋势</h3>
      </div>
      <p class="section-caption forecast-caption">
        展示未来24小时 AQI 变化趋势，帮助你安排出行与活动。
      </p>
    </div>

    <div class="air-hourly-summary">
      <span>当前 {{ summary.latest }}</span>
      <span>峰值 {{ summary.max }}</span>
      <span>低点 {{ summary.min }}</span>
    </div>

    <div class="chart-shell air-hourly-chart-shell">
      <svg
        v-if="forecast.hours.length"
        class="chart air-hourly-chart"
        :viewBox="`0 0 ${width} ${height}`"
        role="img"
        aria-label="未来24小时AQI趋势"
      >
        <g v-for="tick in yAxisTicks" :key="tick.key">
          <line
            :x1="paddingLeft"
            :y1="tick.y"
            :x2="width - paddingRight"
            :y2="tick.y"
            class="grid-line"
          />
          <text
            :x="paddingLeft - 8"
            :y="tick.y + 3"
            text-anchor="end"
            class="axis-label"
          >
            {{ tick.valueLabel }}
          </text>
        </g>

        <line
          :x1="paddingLeft"
          :y1="paddingTop"
          :x2="paddingLeft"
          :y2="height - paddingBottom"
          class="axis-line"
        />
        <line
          :x1="paddingLeft"
          :y1="height - paddingBottom"
          :x2="width - paddingRight"
          :y2="height - paddingBottom"
          class="axis-line"
        />

        <polyline :points="linePoints" class="line air-hourly-line" />

        <g v-for="point in chartPoints" :key="point.key">
          <circle :cx="point.x" :cy="point.y" r="4.5" class="point air-hourly-point" />
          <text
            v-if="point.showValue"
            :x="point.x"
            :y="point.labelY"
            text-anchor="middle"
            class="point-label air-hourly-point-label"
          >
            {{ point.valueLabel }}
          </text>
          <line
            v-if="point.showTick"
            :x1="point.x"
            :y1="height - paddingBottom"
            :x2="point.x"
            :y2="height - paddingBottom + 5"
            class="tick-line"
          />
          <text
            v-if="point.showTick"
            :x="point.x"
            :y="height - 10"
            text-anchor="middle"
            class="tick-label"
          >
            {{ point.timeLabel }}
          </text>
        </g>
      </svg>

      <div v-else class="air-hourly-empty">
        暂无未来24小时空气质量预报数据。
      </div>
    </div>
  </section>
</template>
