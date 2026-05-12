<script setup lang="ts">
import type { DashboardLocation } from '@airnow/shared';

defineProps<{
  location: DashboardLocation;
  provider: string;
  loading: boolean;
  fetchedAt: string;
  cached: boolean;
}>();

defineEmits<{
  refresh: [];
}>();
</script>

<template>
  <section class="panel location-panel">
    <div class="location-copy">
      <p class="eyebrow">当前定位</p>
      <h2>{{ location.city }} · {{ location.district }}</h2>
      <p class="location-meta">
        {{ location.latitude.toFixed(4) }}, {{ location.longitude.toFixed(4) }}
      </p>
      <p class="location-time">Refresh at {{ new Date().toLocaleString('zh-CN') }}</p>
    </div>

    <button
      class="ghost-button location-refresh-button"
      :class="{ 'is-loading': loading }"
      type="button"
      :disabled="loading"
      @click="$emit('refresh')"
    >
      <span v-if="loading" class="button-spinner" aria-hidden="true" />
      {{ loading ? '刷新中...' : '刷新数据' }}
    </button>
  </section>
</template>
