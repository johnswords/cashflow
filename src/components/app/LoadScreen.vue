<template>
  <div class="load-screen">
    <div class="load-screen__panel">
      <h1 class="load-screen__title">Cashflow Arcade</h1>
      <p class="load-screen__subtitle">Select an option to jump into the game.</p>
      <ul class="load-screen__menu">
        <li>
          <button class="menu-button" @click="startNewGame" :disabled="isLoading">New Game</button>
        </li>
        <li>
          <button class="menu-button" @click="openGamesList" :disabled="isLoading">List Games</button>
        </li>
        <li>
          <button class="menu-button" @click="openLeaderboard" :disabled="isLeaderboardLoading">
            Leaderboard
          </button>
        </li>
      </ul>
      <p v-if="error" class="load-screen__error">{{ error }}</p>
    </div>
  </div>
</template>

<script>
import { mapState } from "vuex";

export default {
  name: "LoadScreen",
  computed: {
    ...mapState({
      isLoading: state => state.loading.games,
      isLeaderboardLoading: state => state.loading.leaderboard,
      error: state => state.error
    })
  },
  created() {
    this.$store.dispatch("fetchGames");
  },
  methods: {
    startNewGame() {
      this.$store.dispatch("navigate", "new-game-setup");
    },
    openGamesList() {
      this.$store.dispatch("navigate", "game-list");
    },
    openLeaderboard() {
      this.$store.dispatch("fetchLeaderboard");
    }
  }
};
</script>

<style scoped lang="scss">
.load-screen {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle at center, #231942 0%, #0f0c29 60%, #000 100%);
  color: #f9f4ff;
  text-align: center;
  padding: 2rem;
}

.load-screen__panel {
  border: 4px solid #9c27b0;
  padding: 3rem 4rem;
  border-radius: 12px;
  background: rgba(10, 9, 24, 0.92);
  box-shadow: 0 0 30px rgba(156, 39, 176, 0.45);
}

.load-screen__title {
  font-family: "Press Start 2P", monospace;
  font-size: 1.75rem;
  letter-spacing: 0.1em;
  margin-bottom: 1rem;
}

.load-screen__subtitle {
  opacity: 0.75;
  margin-bottom: 2rem;
}

.load-screen__menu {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.menu-button {
  font-family: "Press Start 2P", monospace;
  font-size: 1rem;
  padding: 1rem 2.5rem;
  border: 3px solid #f4d35e;
  color: #f4d35e;
  background: transparent;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.menu-button:hover:not(:disabled) {
  transform: translateY(-4px);
  box-shadow: 0 0 18px rgba(244, 211, 94, 0.6);
}

.menu-button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.load-screen__error {
  margin-top: 2rem;
  color: #ff8a80;
  font-family: "Press Start 2P", monospace;
  font-size: 0.85rem;
}
</style>
