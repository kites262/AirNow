<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue";
import type { AirInfo } from "@airnow/shared";

const props = defineProps<{
  air: AirInfo;
}>();

const displayedAqi = ref(0);
const animatedColor = ref("rgb(52, 211, 153)");

let animationFrame: number | null = null;

function getTargetColor(aqi: number): [number, number, number] {
  if (aqi <= 50) {
    return [52, 211, 153];
  }

  if (aqi <= 100) {
    return [251, 191, 36];
  }

  if (aqi <= 150) {
    return [251, 113, 133];
  }

  return [249, 115, 22];
}

function parseRgb(color: string) {
  const match = color.match(/\d+/g);

  if (!match || match.length < 3) {
    return [52, 211, 153] as const;
  }

  return match.slice(0, 3).map(Number) as [number, number, number];
}

function toRgbString([r, g, b]: [number, number, number]) {
  return `rgb(${r}, ${g}, ${b})`;
}

function easeOutCubic(progress: number) {
  return 1 - (1 - progress) ** 3;
}

const levelClass = computed(() => {
  if (props.air.aqi <= 50) {
    return "good";
  }

  if (props.air.aqi <= 100) {
    return "moderate";
  }

  if (props.air.aqi <= 150) {
    return "warning";
  }

  return "danger";
});

const aqiProgress = computed(() => `${Math.min(displayedAqi.value, 200) / 200 * 360}deg`);

function formatMetricValue(label: string, value: number) {
  if (label === "CO") {
    return `${value}`;
  }

  return `${Math.round(value)}`;
}

const metrics = computed(() => [
  {
    label: "PM2.5",
    value: formatMetricValue("PM2.5", props.air.pollutants.pm25),
    unit: props.air.unit.pm,
  },
  {
    label: "PM10",
    value: formatMetricValue("PM10", props.air.pollutants.pm10),
    unit: props.air.unit.pm,
  },
  {
    label: "SO2",
    value: formatMetricValue("SO2", props.air.pollutants.so2),
    unit: props.air.unit.pm,
  },
  {
    label: "NO2",
    value: formatMetricValue("NO2", props.air.pollutants.no2),
    unit: props.air.unit.pm,
  },
  {
    label: "O3",
    value: formatMetricValue("O3", props.air.pollutants.o3),
    unit: props.air.unit.pm,
  },
  {
    label: "CO",
    value: formatMetricValue("CO", props.air.pollutants.co),
    unit: props.air.unit.co,
  },
]);

watch(
  () => props.air.aqi,
  (targetAqi) => {
    const startValue = displayedAqi.value;
    const startColor = parseRgb(animatedColor.value);
    const targetColor = getTargetColor(targetAqi);

    if (typeof window === "undefined") {
      displayedAqi.value = targetAqi;
      animatedColor.value = toRgbString(targetColor);
      return;
    }

    if (animationFrame !== null) {
      window.cancelAnimationFrame(animationFrame);
    }

    const startTime = window.performance.now();
    const duration = 1100;

    const tick = (currentTime: number) => {
      const rawProgress = Math.min((currentTime - startTime) / duration, 1);
      const easedProgress = easeOutCubic(rawProgress);

      displayedAqi.value = Math.round(
        startValue + (targetAqi - startValue) * easedProgress,
      );

      animatedColor.value = toRgbString([
        Math.round(startColor[0] + (targetColor[0] - startColor[0]) * easedProgress),
        Math.round(startColor[1] + (targetColor[1] - startColor[1]) * easedProgress),
        Math.round(startColor[2] + (targetColor[2] - startColor[2]) * easedProgress),
      ]);

      if (rawProgress < 1) {
        animationFrame = window.requestAnimationFrame(tick);
        return;
      }

      animationFrame = null;
    };

    animationFrame = window.requestAnimationFrame(tick);
  },
  { immediate: true },
);

onBeforeUnmount(() => {
  if (animationFrame !== null && typeof window !== "undefined") {
    window.cancelAnimationFrame(animationFrame);
  }
});
</script>

<template>
  <section class="panel air-quality-card">
    <div class="section-heading air-quality-heading">
      <div>
        <p class="eyebrow">空气质量</p>
      </div>
    </div>

    <div class="air-panel">
      <div
        class="aqi-ring"
        :class="levelClass"
        :style="{ color: animatedColor, '--aqi-progress': aqiProgress }"
      >
        <span class="aqi-value">{{ displayedAqi }}</span>
        <span class="aqi-label">AQI</span>
      </div>

      <div class="air-copy">
        <h3>{{ air.levelText }}</h3>
        <p class="air-advice">{{ air.advice }}</p>
        <p class="air-time">
          {{ new Date(air.updateTime).toLocaleString("zh-CN") }} 更新
        </p>
      </div>
    </div>

    <div class="air-metrics-divider" />

    <div class="air-metrics-row">
      <article
        v-for="(metric, index) in metrics"
        :key="metric.label"
        class="air-metric-card"
        :style="{ '--metric-index': index }"
      >
        <p class="air-metric-label">{{ metric.label }}</p>
        <strong class="air-metric-value">{{ metric.value }}</strong>
        <span class="air-metric-unit">{{ metric.unit }}</span>
      </article>
    </div>
  </section>
</template>
