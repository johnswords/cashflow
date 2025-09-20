<template>
  <div id="app" :class="['view-' + currentView]">
    <component :is="activeComponent" />
    <audit-log-modal />
    <end-game-modal />
  </div>
</template>

<script>
import { mapState, mapGetters } from "vuex";
import LoadScreen from "@/components/app/LoadScreen.vue";
import NewGameSetup from "@/components/app/NewGameSetup.vue";
import GameList from "@/components/app/GameList.vue";
import GameScreen from "@/components/app/GameScreen.vue";
import PlayerSheetView from "@/components/app/PlayerSheetView.vue";
import LeaderboardView from "@/components/app/LeaderboardView.vue";
import AuditLogModal from "@/components/app/AuditLogModal.vue";
import EndGameModal from "@/components/app/EndGameModal.vue";
import { setAudioEnabled } from "@/utils/audio";

const VIEW_COMPONENTS = {
  "load-screen": LoadScreen,
  "new-game-setup": NewGameSetup,
  "game-list": GameList,
  "game-screen": GameScreen,
  "player-sheet": PlayerSheetView,
  leaderboard: LeaderboardView
};

export default {
  name: "CashflowApp",
  components: { ...VIEW_COMPONENTS, AuditLogModal, EndGameModal },
  computed: {
    ...mapState({
      currentView: state => state.currentView
    }),
    ...mapGetters(["isAudioEnabled"]),
    activeComponent() {
      return VIEW_COMPONENTS[this.currentView] || LoadScreen;
    }
  },
  watch: {
    isAudioEnabled: {
      immediate: true,
      handler(value) {
        setAudioEnabled(value);
      }
    }
  },
  created() {
    if (!this.currentView) {
      this.$store.commit("SET_VIEW", "load-screen");
    }
  }
};
</script>

<style lang="scss">
@import url("https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap");

#app {
  min-height: 100vh;
  background: #040008;
  color: #fdf9ff;
}

button {
  font-family: inherit;
}
</style>
