<template>
  <div class="game-screen" v-if="game">
    <header class="game-screen__header">
      <div>
        <h2>{{ game.title }}</h2>
        <p>Started {{ formatDate(game.createdAt) }} · Last updated {{ formatDate(game.updatedAt) }}</p>
      </div>
      <div class="game-screen__actions">
        <audio-toggle />
        <button @click="goBack">Menu</button>
        <button @click="openLeaderboard" :disabled="isLeaderboardLoading">Leaderboard</button>
        <button @click="triggerEndGame" :disabled="game.status === 'completed'">End Game</button>
      </div>
    </header>

    <section class="game-screen__players">
      <article v-for="player in game.players" :key="player.id" class="player-card" :data-color="player.color">
        <header>
          <h3>{{ player.name }}</h3>
          <span class="badge" :style="{ backgroundColor: player.color }">{{ player.color }}</span>
        </header>
        <dl class="player-card__stats">
          <div>
            <dt>Cash</dt>
            <dd>{{ formatCurrency(summary(player).cash) }}</dd>
          </div>
          <div>
            <dt>Salary</dt>
            <dd>{{ formatCurrency(summary(player).salary) }}</dd>
          </div>
          <div>
            <dt>Passive Income</dt>
            <dd>{{ formatCurrency(summary(player).passiveIncome) }}</dd>
          </div>
          <div>
            <dt>Total Income</dt>
            <dd>{{ formatCurrency(summary(player).totalIncome) }}</dd>
          </div>
          <div>
            <dt>Total Expenses</dt>
            <dd>{{ formatCurrency(summary(player).totalExpenses) }}</dd>
          </div>
          <div>
            <dt>Cashflow</dt>
            <dd :class="{ positive: summary(player).cashflow >= 0, negative: summary(player).cashflow < 0 }">
              {{ formatCurrency(summary(player).cashflow) }}
            </dd>
          </div>
          <div>
            <dt>Kids</dt>
            <dd>
              {{ summary(player).children }}
              <span v-if="summary(player).children">@ {{ formatCurrency(summary(player).perChildExpense) }}</span>
            </dd>
          </div>
        </dl>
        <footer class="player-card__actions">
          <button @click="openSheet(player)">Open Sheet</button>
          <button @click="viewAuditLog(player)" class="ghost">Audit Log</button>
        </footer>
        <section v-if="recentChanges(player).length" class="player-card__recent">
          <h4>Recent Changes</h4>
          <ul>
            <li v-for="entry in recentChanges(player)" :key="entry.id">
              <span class="time">{{ formatTime(entry.timestamp) }}</span>
              <span class="type" :class="entry.entryType">{{ entry.entryType }}</span>
              <span class="fields">
                {{ entry.fieldPaths.map(formatFieldPath).join(', ') }}
              </span>
            </li>
          </ul>
        </section>
      </article>
    </section>
  </div>
  <div v-else class="game-screen__empty">
    <p>No game selected.</p>
    <button @click="goBack">Back to Menu</button>
  </div>
</template>

<script>
import { mapState, mapGetters } from "vuex";
import { computeSummary } from "@/utils/cashflow";
import AudioToggle from "@/components/app/AudioToggle.vue";

const SECTION_LABELS = {
  income: "Income",
  expenses: "Expenses",
  liabilities: "Liabilities",
  assets: "Assets",
  investments: "Investments",
  meta: "Profile",
  fasttrack: "Fast Track"
};

export default {
  name: "GameScreen",
  components: { AudioToggle },
  computed: {
    ...mapState({
      game: state => state.activeGame,
      isLeaderboardLoading: state => state.loading.leaderboard
    }),
    ...mapGetters(["auditEntriesByPlayer"])
  },
  methods: {
    formatDate(value) {
      if (!value) return "Unknown";
      return new Date(value).toLocaleString();
    },
    formatCurrency(value) {
      return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(Number(value || 0));
    },
    formatTime(value) {
      return new Date(value).toLocaleTimeString();
    },
    formatFieldPath(path) {
      if (!path) return "";
      const segments = path.split(".");
      if (!segments.length) return path;
      const [head, ...rest] = segments;
      const formatted = [SECTION_LABELS[head] || this.startCase(head), ...rest.map(this.startCase)];
      return formatted.join(" → ");
    },
    startCase(value) {
      if (!value) return "";
      return value
        .replace(/([A-Z])/g, " $1")
        .replace(/[_-]/g, " ")
        .replace(/\s+/g, " ")
        .trim()
        .replace(/^./, char => char.toUpperCase());
    },
    summary(player) {
      return computeSummary(player.sheetState || {});
    },
    goBack() {
      this.$store.dispatch("navigate", "load-screen");
    },
    openLeaderboard() {
      this.$store.dispatch("fetchLeaderboard");
    },
    triggerEndGame() {
      this.$store.dispatch("openEndGameModal");
    },
    openSheet(player) {
      this.$store.dispatch("selectPlayer", player.id);
      this.$store.dispatch("navigate", "player-sheet");
    },
    viewAuditLog(player) {
      this.$store.dispatch("openAuditLog", player.id);
    },
    recentChanges(player) {
      return this.auditEntriesByPlayer(player.id).slice(0, 3);
    }
  }
};
</script>

<style scoped lang="scss">
.game-screen {
  min-height: 100vh;
  padding: 2.5rem 3rem 4rem;
  background: linear-gradient(145deg, #120024, #010409 70%);
  color: #f6f3ff;
}

.game-screen__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 2rem;
  font-family: "Press Start 2P", monospace;
}

.game-screen__header h2 {
  margin: 0 0 0.4rem;
}

.game-screen__header p {
  margin: 0;
  font-size: 0.8rem;
  opacity: 0.75;
}

.game-screen__actions {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.game-screen__actions button {
  padding: 0.6rem 1.4rem;
  border: 2px solid rgba(244, 211, 94, 0.65);
  background: transparent;
  color: rgba(244, 211, 94, 0.9);
  font-family: "Press Start 2P", monospace;
  cursor: pointer;
}

.game-screen__players {
  display: grid;
  gap: 1.5rem;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
}

.player-card {
  background: rgba(12, 12, 40, 0.85);
  border: 3px solid rgba(123, 97, 255, 0.5);
  border-radius: 18px;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.player-card:hover {
  transform: translateY(-6px);
  box-shadow: 0 12px 30px rgba(123, 97, 255, 0.35);
}

.player-card header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.player-card h3 {
  font-family: "Press Start 2P", monospace;
  font-size: 0.9rem;
  margin: 0;
}

.badge {
  border-radius: 999px;
  padding: 0.35rem 0.75rem;
  font-size: 0.7rem;
  text-transform: uppercase;
  color: #1a093a;
  font-weight: 700;
}

.player-card__stats {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.75rem 1rem;
  margin: 0;
}

.player-card__stats dt {
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  opacity: 0.6;
}

.player-card__stats dd {
  margin: 0;
  font-size: 1rem;
}

.player-card__stats dd.positive {
  color: #9cff94;
}

.player-card__stats dd.negative {
  color: #ff8a80;
}

.player-card__actions {
  display: flex;
  gap: 1rem;
}

.player-card__actions button {
  flex: 1;
  padding: 0.7rem 0;
  border: 2px solid rgba(244, 211, 94, 0.6);
  background: rgba(10, 10, 30, 0.95);
  color: rgba(244, 211, 94, 0.9);
  font-family: "Press Start 2P", monospace;
  cursor: pointer;
}

.player-card__actions .ghost {
  border-color: rgba(156, 39, 176, 0.6);
  color: rgba(156, 39, 176, 0.85);
}

.player-card__recent {
  border-top: 1px solid rgba(244, 211, 94, 0.2);
  padding-top: 1rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
}

.player-card__recent h4 {
  margin: 0 0 0.6rem;
  font-size: 0.7rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.player-card__recent ul {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.45rem;
}

.player-card__recent li {
  display: grid;
  grid-template-columns: auto auto 1fr;
  gap: 0.5rem;
  align-items: center;
}

.player-card__recent .time {
  opacity: 0.7;
}

.player-card__recent .type.correction {
  color: #9cff94;
}

.player-card__recent .type.turn {
  color: rgba(244, 211, 94, 0.9);
}

.player-card__recent .fields {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.game-screen__empty {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #08001a;
  color: #fdf9ff;
  gap: 1rem;
}

.game-screen__empty button {
  padding: 0.6rem 1.5rem;
  border: 2px solid rgba(244, 211, 94, 0.6);
  background: transparent;
  color: rgba(244, 211, 94, 0.9);
  font-family: "Press Start 2P", monospace;
  cursor: pointer;
}
</style>
