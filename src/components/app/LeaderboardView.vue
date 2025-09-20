<template>
  <div class="leaderboard">
    <header class="leaderboard__header">
      <button class="back-button" @click="goBack">⟵ Back</button>
      <h2>Leaderboard</h2>
      <span v-if="isLoading" class="loading">Loading…</span>
    </header>
    <table v-if="entries.length" class="leaderboard__table">
      <thead>
        <tr>
          <th>Rank</th>
          <th>Player</th>
          <th>Game</th>
          <th>Cashflow</th>
          <th>Completed</th>
          <th>Comment</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="entry in entries" :key="entry.id">
          <td>{{ entry.rank }}</td>
          <td>
            <span class="color" :style="{ backgroundColor: entry.player.color }"></span>
            {{ entry.player.name }}
          </td>
          <td>
            <button class="link" @click="openGame(entry.game.id)">{{ entry.game.title }}</button>
          </td>
          <td>{{ formatCurrency(entry.cashflowValue) }}</td>
          <td>{{ formatDate(entry.game.completedAt) }}</td>
          <td>{{ entry.winnerComment || "—" }}</td>
        </tr>
      </tbody>
    </table>
    <div v-else class="leaderboard__empty">
      <p>No completed games yet — go win one!</p>
    </div>
  </div>
</template>

<script>
import { mapState } from "vuex";

export default {
  name: "LeaderboardView",
  computed: {
    ...mapState({
      entries: state => state.leaderboard,
      isLoading: state => state.loading.leaderboard
    })
  },
  methods: {
    goBack() {
      this.$store.dispatch("navigate", "load-screen");
    },
    formatCurrency(value) {
      return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(Number(value || 0));
    },
    formatDate(value) {
      if (!value) return "Unknown";
      return new Date(value).toLocaleDateString();
    },
    openGame(gameId) {
      this.$store.dispatch("loadGame", gameId);
    }
  }
};
</script>

<style scoped lang="scss">
.leaderboard {
  min-height: 100vh;
  padding: 2.5rem 3rem;
  background: radial-gradient(circle at top, #1b0f3a, #020202 80%);
  color: #f8f4ff;
}

.leaderboard__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 2rem;
  font-family: "Press Start 2P", monospace;
}

.back-button {
  border: 2px solid rgba(244, 211, 94, 0.6);
  background: transparent;
  color: rgba(244, 211, 94, 0.9);
  padding: 0.6rem 1.2rem;
  cursor: pointer;
}

.loading {
  font-size: 0.8rem;
  opacity: 0.7;
}

.leaderboard__table {
  width: 100%;
  border-collapse: collapse;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
}

.leaderboard__table th,
.leaderboard__table td {
  border-bottom: 1px solid rgba(244, 211, 94, 0.2);
  padding: 0.9rem 0.75rem;
  text-align: left;
}

.leaderboard__table th {
  text-transform: uppercase;
  letter-spacing: 0.08em;
  opacity: 0.7;
}

.color {
  width: 0.9rem;
  height: 0.9rem;
  border-radius: 50%;
  display: inline-block;
  margin-right: 0.6rem;
  border: 2px solid #fff;
}

.link {
  background: none;
  border: none;
  color: #9cf6ff;
  cursor: pointer;
  text-decoration: underline;
  padding: 0;
  font-family: inherit;
}

.leaderboard__empty {
  text-align: center;
  margin-top: 4rem;
  font-family: "Press Start 2P", monospace;
  opacity: 0.75;
}
</style>
