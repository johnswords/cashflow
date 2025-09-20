<template>
  <div class="fast-track">
    <fast-track-page />
  </div>
</template>

<script>
import FastTrackPage from "@/components/fasttrack/FastTrackPage.vue";

export default {
  components: { FastTrackPage }
};
</script>

<style scoped lang="scss">
.fast-track {
  position: relative;
  max-width: 1040px;
  margin: 0 auto;
  padding: 2rem 0 2.5rem;
  display: flex;
  flex-direction: column;
  gap: 2rem;
  color: #f6f3ff;
}

@media (max-width: 768px) {
  .fast-track {
    padding: 1.5rem 0 2rem;
  }
}
</style>
