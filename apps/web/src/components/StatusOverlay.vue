<script setup lang="ts">
defineProps<{
  loading: boolean;
  error: string;
  hasData: boolean;
}>();

defineEmits<{
  retry: [];
}>();
</script>

<template>
  <section v-if="loading || error || !hasData" class="panel status-panel">
    <div v-if="loading" class="status-block">
      <div class="status-loader" aria-hidden="true">
        <span />
        <span />
        <span />
      </div>
      <p class="eyebrow">同步中</p>
      <h2>正在获取天气和空气质量数据</h2>
      <p>第一次启动会先请求后端 mock provider，完成后会自动展示首页内容。</p>
    </div>

    <div v-else-if="error" class="status-block">
      <p class="eyebrow">请求失败</p>
      <h2>{{ error }}</h2>
      <button class="ghost-button" type="button" @click="$emit('retry')">重新加载</button>
    </div>

    <div v-else class="status-block">
      <p class="eyebrow">暂无数据</p>
      <h2>点击下方按钮拉取第一份演示数据</h2>
      <button class="ghost-button" type="button" @click="$emit('retry')">开始加载</button>
    </div>
  </section>
</template>
