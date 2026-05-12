<script setup lang="ts">
import { computed } from "vue";
import type { ForecastDay } from "@airnow/shared";

const props = defineProps<{
  days: ForecastDay[];
}>();

const width = 320;
const height = 196;
const paddingLeft = 36;
const paddingRight = 18;
const paddingTop = 24;
const paddingBottom = 34;
const yAxisTickCount = 4;

const chartBounds = computed(() => {
  if (props.days.length === 0) {
    return { min: 0, max: 10 };
  }

  const values = props.days.flatMap((day) => [day.tempMax, day.tempMin]);
  const min = Math.min(...values) - 2;
  const max = Math.max(...values) + 2;
  return { min, max };
});

const humBounds = computed(() => {
  if (props.days.length === 0) {
    return { min: 0, max: 100 };
  }

  const values = props.days.map((day) => day.humidity);
  const rawMin = Math.min(...values);
  const rawMax = Math.max(...values);
  const min = Math.max(0, Math.floor((rawMin - 10) / 10) * 10);
  const max = Math.min(100, Math.ceil((rawMax + 10) / 10) * 10);
  return { min, max };
});

const usableWidth = width - paddingLeft - paddingRight;
const usableHeight = height - paddingTop - paddingBottom;

function getX(index: number) {
  return paddingLeft + (usableWidth / Math.max(props.days.length - 1, 1)) * index;
}

function resolveY(value: number, bounds: { min: number; max: number }) {
  const normalized = (value - bounds.min) / Math.max(bounds.max - bounds.min, 1);
  return height - paddingBottom - normalized * usableHeight;
}

function toPoints(selector: (day: ForecastDay) => number, bounds: { min: number; max: number }) {
  if (props.days.length === 0) {
    return "";
  }

  return props.days
    .map((day, index) => {
      const x = getX(index);
      const y = resolveY(selector(day), bounds);
      return `${x},${y}`;
    })
    .join(" ");
}

const maxLine = computed(() => toPoints((day) => day.tempMax, chartBounds.value));
const minLine = computed(() => toPoints((day) => day.tempMin, chartBounds.value));
const humLine = computed(() => toPoints((day) => day.humidity, humBounds.value));
const chartPoints = computed(() =>
  props.days.map((day, index) => ({
    key: day.date,
    x: getX(index),
    maxY: resolveY(day.tempMax, chartBounds.value),
    minY: resolveY(day.tempMin, chartBounds.value),
    tempMax: day.tempMax,
    tempMin: day.tempMin,
  })),
);
const humChartPoints = computed(() =>
  props.days.map((day, index) => ({
    key: day.date,
    x: getX(index),
    humY: resolveY(day.humidity, humBounds.value),
    humidity: day.humidity,
  })),
);
const yAxisTicks = computed(() => {
  const { min, max } = chartBounds.value;
  const step = (max - min) / Math.max(yAxisTickCount - 1, 1);

  return Array.from({ length: yAxisTickCount }, (_, index) => {
    const value = max - step * index;
    const y = resolveY(value, chartBounds.value);

    return {
      key: `${index}-${value}`,
      value: Math.round(value),
      y,
    };
  });
});
const humYAxisTicks = computed(() => {
  const { min, max } = humBounds.value;
  const step = (max - min) / Math.max(yAxisTickCount - 1, 1);

  return Array.from({ length: yAxisTickCount }, (_, index) => {
    const value = max - step * index;
    const y = resolveY(value, humBounds.value);

    return {
      key: `hum-${index}-${value}`,
      value: Math.round(value),
      y,
    };
  });
});
const dateTicks = computed(() => {
  return props.days.map((day, index) => ({
    key: day.date,
    label: day.date.slice(5),
    x: getX(index),
  }));
});
</script>

<template>
  <section class="panel">
    <div class="section-heading forecast-heading">
      <div>
        <p class="eyebrow">未来天气</p>
        <h3>温度趋势</h3>
      </div>
      <p class="section-caption forecast-caption">
        未来几天的最高温和最低温趋势，帮助你更好地规划出行和活动。
      </p>
    </div>

    <div class="chart-shell">
      <svg
        class="chart"
        :viewBox="`0 0 ${width} ${height}`"
        role="img"
        aria-label="未来天气温度趋势"
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
            {{ tick.value }}°
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
        <polyline :points="maxLine" class="line max-line" />
        <polyline :points="minLine" class="line min-line" />
        <g v-for="point in chartPoints" :key="point.key">
          <circle :cx="point.x" :cy="point.maxY" r="4.5" class="point max-point" />
          <text
            :x="point.x"
            :y="point.maxY - 10"
            text-anchor="middle"
            class="point-label max-point-label"
          >
            {{ point.tempMax }}°
          </text>
          <circle :cx="point.x" :cy="point.minY" r="4.5" class="point min-point" />
          <text
            :x="point.x"
            :y="point.minY + 16"
            text-anchor="middle"
            class="point-label min-point-label"
          >
            {{ point.tempMin }}°
          </text>
        </g>
        <g v-for="tick in dateTicks" :key="tick.key">
          <line
            :x1="tick.x"
            :y1="height - paddingBottom"
            :x2="tick.x"
            :y2="height - paddingBottom + 5"
            class="tick-line"
          />
          <text
            :x="tick.x"
            :y="height - 10"
            text-anchor="middle"
            class="tick-label"
          >
            {{ tick.label }}
          </text>
        </g>
      </svg>
    </div>

    <div class="section-heading forecast-heading hum-heading">
      <h3>湿度趋势</h3>
    </div>

    <div class="chart-shell">
      <svg
        class="chart"
        :viewBox="`0 0 ${width} ${height}`"
        role="img"
        aria-label="未来天气湿度趋势"
      >
        <g v-for="tick in humYAxisTicks" :key="tick.key">
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
            {{ tick.value }}%
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
        <polyline :points="humLine" class="line hum-line" />
        <g v-for="point in humChartPoints" :key="point.key">
          <circle :cx="point.x" :cy="point.humY" r="4.5" class="point hum-point" />
          <text
            :x="point.x"
            :y="point.humY - 10"
            text-anchor="middle"
            class="point-label hum-point-label"
          >
            {{ point.humidity }}%
          </text>
        </g>
        <g v-for="tick in dateTicks" :key="tick.key">
          <line
            :x1="tick.x"
            :y1="height - paddingBottom"
            :x2="tick.x"
            :y2="height - paddingBottom + 5"
            class="tick-line"
          />
          <text
            :x="tick.x"
            :y="height - 10"
            text-anchor="middle"
            class="tick-label"
          >
            {{ tick.label }}
          </text>
        </g>
      </svg>
    </div>

    <div class="forecast-strip">
      <article
        v-for="(day, index) in days"
        :key="day.date"
        class="forecast-day"
        :style="{ '--forecast-index': index }"
      >
        <p class="forecast-date">{{ day.date.slice(5) }}</p>
        <strong>{{ day.tempMax }}°C / {{ day.tempMin }}°C</strong>
        <span>湿度 {{ day.humidity }}%</span>
      </article>
    </div>
  </section>
</template>
