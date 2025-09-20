<template>
  <button class="audio-toggle" @click="toggle">
    <span v-if="enabled">🔊</span>
    <span v-else>🔇</span>
  </button>
</template>

<script>
import { mapGetters } from "vuex";

export default {
  name: "AudioToggle",
  computed: {
    ...mapGetters(["isAudioEnabled"]),
    enabled() {
      return this.isAudioEnabled;
    }
  },
  methods: {
    toggle() {
      this.$store.dispatch("toggleAudio");
    }
  }
};
</script>

<style scoped lang="scss">
.audio-toggle {
  background: rgba(10, 10, 28, 0.9);
  border: 2px solid rgba(244, 211, 94, 0.6);
  color: rgba(244, 211, 94, 0.9);
  cursor: pointer;
  font-size: 1.2rem;
  padding: 0.3rem 0.6rem;
  border-radius: 8px;
}
</style>
