<script setup lang="ts">
import {
  computed,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
  watch,
} from "vue";

import AirQualityCard from "./components/AirQualityCard.vue";
import ForecastChart from "./components/ForecastChart.vue";
import HourlyAirForecastCard from "./components/HourlyAirForecastCard.vue";
import StatusOverlay from "./components/StatusOverlay.vue";
import { useDashboard } from "./composables/useDashboard";

const cityPresets = [
  { name: "西安", latitude: 34.123403, longitude: 108.837443 },
  { name: "北京", latitude: 39.9042, longitude: 116.4074 },
  { name: "上海", latitude: 31.2304, longitude: 121.4737 },
  { name: "广州", latitude: 23.1291, longitude: 113.2644 },
  { name: "成都", latitude: 30.5728, longitude: 104.0668 },
];

const { data, error, hasData, isInitialLoading, isRefreshing, load, refresh } =
  useDashboard();
const activeCity = ref(cityPresets[0].name);
const isCityPickerOpen = ref(false);
const currentLocationCity = "西安";
const pageError = computed(() => (hasData.value ? "" : error.value));
const appShell = ref<HTMLElement | null>(null);

let revealObserver: IntersectionObserver | null = null;

function setupRevealMotion() {
  const root = appShell.value;

  if (!root || typeof window === "undefined") {
    return;
  }

  const revealNodes = Array.from(
    root.querySelectorAll<HTMLElement>("[data-reveal]"),
  );
  const prefersReducedMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)",
  ).matches;

  if (prefersReducedMotion || !("IntersectionObserver" in window)) {
    revealNodes.forEach((node) => node.classList.add("is-visible"));
    return;
  }

  revealObserver?.disconnect();
  revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const target = entry.target as HTMLElement;
          target.classList.add("is-visible");
          revealObserver?.unobserve(target);
        }
      });
    },
    {
      threshold: 0.16,
      rootMargin: "0px 0px -10% 0px",
    },
  );

  revealNodes.forEach((node) => {
    if (!node.classList.contains("is-visible")) {
      revealObserver?.observe(node);
    }
  });
}

async function switchCity(name: string, latitude: number, longitude: number) {
  activeCity.value = name;
  isCityPickerOpen.value = false;
  await load({ latitude, longitude });
}

function handleHeroRefresh() {
  if (!hasData.value || isRefreshing.value) {
    return;
  }

  refresh();
}

watch(data, async (dashboard) => {
  if (!dashboard) {
    return;
  }

  await nextTick();
  setupRevealMotion();
});

onMounted(async () => {
  await load();
  await nextTick();
  setupRevealMotion();

  if ("geolocation" in navigator) {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        console.log("[Geolocation]", { latitude, longitude });
        load({ latitude, longitude }).then(() => {
          console.log("[Geolocation Weather]", {
            latitude,
            longitude,
            data: data.value,
          });
        });
      },
      (err) => {
        console.warn("[Geolocation]", err.message);
      },
      { enableHighAccuracy: true, timeout: 10_000 },
    );
  }
});

onBeforeUnmount(() => {
  revealObserver?.disconnect();
});
</script>

<template>
  <main ref="appShell" class="app-shell">
    <section
      class="hero-card page-intro"
      :class="{ 'is-refreshable': hasData }"
      :tabindex="hasData ? 0 : undefined"
      :aria-busy="isRefreshing"
      role="button"
      @click="handleHeroRefresh"
      @keydown.enter.prevent="handleHeroRefresh"
      @keydown.space.prevent="handleHeroRefresh"
    >
      <div v-if="data" class="hero-top">
        <div v-if="data" class="hero-location">
          <p class="eyebrow">当前定位</p>
          <p class="hero-location-title">
            {{ data.location.city }} · {{ data.location.district }}
          </p>
          <p v-if="data.location.detail" class="hero-location-detail">
            {{ data.location.detail }}
          </p>
          <p class="location-meta">
            {{ data.location.latitude.toFixed(4) }},
            {{ data.location.longitude.toFixed(4) }}
          </p>
        </div>

        <div class="hero-actions">
          <button
            class="city-picker-trigger hero-city-picker"
            type="button"
            :aria-expanded="isCityPickerOpen"
            @click.stop="isCityPickerOpen = !isCityPickerOpen"
          >
            <span>城市选择</span>
            <strong>{{ activeCity }}</strong>
          </button>
        </div>
      </div>
    </section>

    <Transition name="modal-float">
      <div
        v-if="isCityPickerOpen"
        class="city-picker-backdrop"
        @click="isCityPickerOpen = false"
      >
        <section class="city-picker-modal" @click.stop>
          <div class="city-picker-group">
            <p class="city-picker-label">当前定位</p>
            <button class="city-picker-row location-row" type="button">
              <svg
                class="location-icon"
                viewBox="0 0 24 24"
                aria-hidden="true"
                fill="none"
                stroke="currentColor"
                stroke-width="1.8"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="M12 3v3" />
                <path d="M12 18v3" />
                <path d="M3 12h3" />
                <path d="M18 12h3" />
                <circle cx="12" cy="12" r="4" />
              </svg>
              <span>定位城市: {{ currentLocationCity }}</span>
            </button>
          </div>

          <div class="city-picker-divider" />

          <div class="city-picker-group">
            <p class="city-picker-label">预置城市</p>
            <div class="city-picker-list">
              <button
                v-for="city in cityPresets"
                :key="city.name"
                class="city-chip"
                :class="{ active: city.name === activeCity }"
                type="button"
                @click="switchCity(city.name, city.latitude, city.longitude)"
              >
                {{ city.name }}
              </button>
            </div>
          </div>
        </section>
      </div>
    </Transition>

    <Transition name="overlay-fade" appear>
      <StatusOverlay
        v-if="isInitialLoading || pageError || !hasData"
        :loading="isInitialLoading"
        :error="pageError"
        :has-data="hasData"
        @retry="refresh"
      />
    </Transition>

    <div v-if="data" class="dashboard-content">
      <div class="reveal-card" data-reveal style="--reveal-delay: 60ms">
        <AirQualityCard :air="data.air" />
      </div>

      <div class="reveal-card" data-reveal style="--reveal-delay: 120ms">
        <HourlyAirForecastCard :forecast="data.airHourlyForecast" />
      </div>

      <div class="reveal-card" data-reveal style="--reveal-delay: 180ms">
        <ForecastChart :days="data.forecast.days" />
      </div>

      <div class="reveal-card" data-reveal style="--reveal-delay: 240ms">
        <section class="footer-note">
          <div>
            <p class="eyebrow">开发信息</p>
            <p>
              {{ data.meta.provider }} ·
              {{ data.meta.cached ? "cache" : "fetch" }}
            </p>
            <p class="footer-meta-time">
              {{ data.meta.cached ? "缓存更新于" : "刷新于" }}
              {{ new Date(data.meta.fetchedAt).toLocaleString("zh-CN") }}
            </p>
          </div>
        </section>
      </div>
    </div>
  </main>
</template>
