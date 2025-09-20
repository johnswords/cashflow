<template>
  <div id="app" :class="['view-' + currentView]">
    <component
      :is="activeComponent"
      @end-game="handleEndGame"
    />
  </div>
</template>

<script>
import { mapState } from "vuex";
import LoadScreen from "@/components/app/LoadScreen.vue";
import NewGameSetup from "@/components/app/NewGameSetup.vue";
import GameList from "@/components/app/GameList.vue";
import GameScreen from "@/components/app/GameScreen.vue";
import PlayerSheetView from "@/components/app/PlayerSheetView.vue";
import LeaderboardView from "@/components/app/LeaderboardView.vue";

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
  components: VIEW_COMPONENTS,
  computed: {
    ...mapState({
      currentView: state => state.currentView
    }),
    activeComponent() {
      return VIEW_COMPONENTS[this.currentView] || LoadScreen;
    }
  },
  created() {
    if (!this.currentView) {
      this.$store.commit("SET_VIEW", "load-screen");
    }
  },
  methods: {
    async handleEndGame() {
      const player = this.$store.getters.activePlayer;
      if (!player) return;
      const shouldEnd = window.confirm(`End the game and crown ${player.name}?`);
      if (!shouldEnd) return;
      const comment = window.prompt("Winner comment (optional)", "");
      try {
        await this.$store.dispatch("completeGame", {
          winnerPlayerId: player.id,
          winnerComment: comment || undefined
        });
        await this.$store.dispatch("fetchLeaderboard");
      } catch (error) {
        // handled via store error state
      }
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
