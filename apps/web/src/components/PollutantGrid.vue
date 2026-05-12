<script setup lang="ts">
import { computed } from 'vue';
import type { AirInfo } from '@airnow/shared';

const props = defineProps<{
  air: AirInfo;
}>();

const metrics = computed(() => [
  { label: 'PM2.5', value: props.air.pollutants.pm25, unit: props.air.unit.pm },
  { label: 'PM10', value: props.air.pollutants.pm10, unit: props.air.unit.pm },
  { label: 'SO2', value: props.air.pollutants.so2, unit: props.air.unit.pm },
  { label: 'NO2', value: props.air.pollutants.no2, unit: props.air.unit.pm },
  { label: 'O3', value: props.air.pollutants.o3, unit: props.air.unit.pm },
  { label: 'CO', value: props.air.pollutants.co, unit: props.air.unit.co },
]);
</script>

<template>
  <section class="panel">
    <div class="section-heading">
      <div>
        <p class="eyebrow">污染物面板</p>
        <h3>核心指标</h3>
      </div>
    </div>

    <div class="pollutant-grid">
      <article v-for="metric in metrics" :key="metric.label" class="metric-card">
        <p class="metric-label">{{ metric.label }}</p>
        <strong class="metric-value">{{ metric.value }}</strong>
        <span class="metric-unit">{{ metric.unit }}</span>
      </article>
    </div>
  </section>
</template>
