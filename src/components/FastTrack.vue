<template>
  <div id="fast-track">
    <fast-track-page />
  </div>
</template>

<script>
import FastTrackPage from "@/components/fasttrack/FastTrackPage.vue";

export default {
  components: { FastTrackPage }
};
</script>

<style lang="scss">
#fast-track {
  display: flex;
  justify-content: center;
}

#fast-track > * {
  width: min(100%, 1100px);
}
</style>
