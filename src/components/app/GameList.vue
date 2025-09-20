<template>
  <div class="game-list">
    <header class="game-list__header">
      <button class="back-button" @click="goBack">⟵ Back</button>
      <h2>Saved Games</h2>
      <button class="refresh-button" @click="refresh" :disabled="isLoading">Refresh</button>
    </header>

    <section v-if="games.length" class="game-list__grid">
      <article v-for="game in games" :key="game.id" class="game-card" :data-status="game.status">
        <header>
          <h3>{{ game.title }}</h3>
          <span class="status" :class="game.status">{{ game.status }}</span>
        </header>
        <p class="timestamp">Last played: {{ formatDate(game.updatedAt || game.createdAt) }}</p>
        <ul class="players">
          <li v-for="player in game.players" :key="player.id">
            <span class="color-indicator" :style="{ backgroundColor: player.color }"></span>
            {{ player.name }}
          </li>
        </ul>
        <footer class="actions">
          <button @click="resume(game)" :disabled="isLoading">Resume</button>
          <button v-if="game.status === 'completed'" @click="viewAudit(game)" :disabled="isLoading">Audit Log</button>
          <button v-else @click="endGame(game)" :disabled="isLoading">End Game</button>
        </footer>
      </article>
    </section>

    <div v-else class="game-list__empty">
      <p>No games yet. Start a new adventure!</p>
    </div>

    <p v-if="error" class="game-list__error">{{ error }}</p>
  </div>
</template>

<script>
import { mapState } from "vuex";

export default {
  name: "GameList",
  computed: {
    ...mapState({
      games: state => state.games,
      isLoading: state => state.loading.games || state.loading.game,
      error: state => state.error
    })
  },
  created() {
    this.refresh();
  },
  methods: {
    goBack() {
      this.$store.dispatch("navigate", "load-screen");
    },
    refresh() {
      this.$store.dispatch("fetchGames");
    },
    formatDate(value) {
      if (!value) return "Unknown";
      const date = new Date(value);
      return date.toLocaleString();
    },
    resume(game) {
      this.$store.dispatch("loadGame", game.id);
    },
    viewAudit(game) {
      this.$store.dispatch("loadGame", game.id).then(() => {
        this.$store.dispatch("fetchAudit", { reset: true });
      });
    },
    endGame(game) {
      this.$store.dispatch("loadGame", game.id).then(() => {
        this.$store.dispatch("navigate", "game-screen");
      });
    }
  }
};
</script>

<style scoped lang="scss">
.game-list {
  min-height: 100vh;
  padding: 2.5rem 3rem;
  background: radial-gradient(circle at top, #2d1b64 0%, #000 85%);
  color: #fdf9ff;
}

.game-list__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 2rem;
  font-family: "Press Start 2P", monospace;
}

.back-button,
.refresh-button {
  background: none;
  border: 2px solid rgba(244, 211, 94, 0.6);
  color: rgba(244, 211, 94, 0.9);
  padding: 0.5rem 1.25rem;
  cursor: pointer;
}

.game-list__grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 1.5rem;
}

.game-card {
  background: rgba(12, 12, 34, 0.85);
  border: 3px solid rgba(156, 39, 176, 0.6);
  border-radius: 14px;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  box-shadow: 0 0 20px rgba(156, 39, 176, 0.3);
}

.game-card[data-status="completed"] {
  border-color: rgba(67, 160, 71, 0.6);
}

.game-card header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.game-card h3 {
  font-family: "Press Start 2P", monospace;
  font-size: 0.95rem;
  margin: 0;
}

.status {
  padding: 0.3rem 0.6rem;
  border-radius: 999px;
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.status.active {
  background: rgba(244, 211, 94, 0.22);
  color: #f4d35e;
}

.status.completed {
  background: rgba(76, 175, 80, 0.2);
  color: #9cff94;
}

.timestamp {
  font-size: 0.8rem;
  opacity: 0.75;
}

.players {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  font-size: 0.85rem;
}

.color-indicator {
  display: inline-block;
  width: 0.9rem;
  height: 0.9rem;
  border-radius: 50%;
  margin-right: 0.6rem;
  border: 2px solid #fff;
}

.actions {
  margin-top: auto;
  display: flex;
  gap: 0.75rem;
}

.actions button {
  flex: 1;
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  padding: 0.6rem 0.4rem;
  background: rgba(10, 10, 28, 0.9);
  border: 2px solid rgba(244, 211, 94, 0.6);
  color: rgba(244, 211, 94, 0.9);
  cursor: pointer;
}

.actions button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.game-list__empty {
  text-align: center;
  opacity: 0.75;
  font-family: "Press Start 2P", monospace;
}

.game-list__error {
  margin-top: 2rem;
  text-align: center;
  color: #ff8a80;
  font-family: "Press Start 2P", monospace;
}
</style>
