import { computed, ref } from "vue";
import type { DashboardRequest, DashboardResponse } from "@airnow/shared";

import { config } from "../config";

const defaultRequest: DashboardRequest = {
  latitude: 34.123403,
  longitude: 108.837443,
};

function joinApiPath(path: string) {
  return `${config.apiBase}${path || ""}` || "/";
}

export function useDashboard() {
  const request = ref<DashboardRequest>({ ...defaultRequest });
  const data = ref<DashboardResponse | null>(null);
  const loading = ref(false);
  const error = ref("");
  const hasData = computed(() => Boolean(data.value));
  let retriedForDetail = false;
  let retryTimer: ReturnType<typeof setTimeout> | null = null;

  async function load(nextRequest?: Partial<DashboardRequest>) {
    if (nextRequest) {
      request.value = {
        ...request.value,
        ...nextRequest,
      };
      retriedForDetail = false;
    }

    if (retryTimer) {
      clearTimeout(retryTimer);
      retryTimer = null;
    }

    loading.value = true;
    error.value = "";

    try {
      const response = await fetch(joinApiPath("/dashboard"), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-Client": "web",
        },
        body: JSON.stringify(request.value),
      });

      if (!response.ok) {
        const fallback = `请求失败（${response.status}）`;
        const payload = (await response.json().catch(() => null)) as {
          message?: string;
        } | null;
        throw new Error(payload?.message ?? fallback);
      }

      data.value = (await response.json()) as DashboardResponse;

      if (!data.value?.location.detail && !retriedForDetail) {
        retriedForDetail = true;
        retryTimer = setTimeout(() => load(), 1000);
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : "加载失败，请稍后再试";
    } finally {
      loading.value = false;
    }
  }

  return {
    data,
    error,
    hasData,
    isInitialLoading: computed(() => loading.value && !hasData.value),
    isRefreshing: computed(() => loading.value && hasData.value),
    loading,
    request,
    load,
    refresh: () => {
      retriedForDetail = false;
      return load();
    },
  };
}
