<template>
  <transition name="fade">
    <div v-if="visible" class="end-game-modal">
      <div class="end-game-modal__panel">
        <header>
          <h3>End Game</h3>
          <button class="close" @click="close">✕</button>
        </header>
        <form @submit.prevent="submit">
          <label>
            Winner
            <select v-model="winnerPlayerId" required>
              <option disabled value="">Select winner</option>
              <option v-for="player in players" :key="player.id" :value="player.id">
                {{ player.name }}
              </option>
            </select>
          </label>
          <section v-if="winnerSummary" class="winner-summary">
            <h4>Final Snapshot</h4>
            <ul>
              <li><span>Cash</span><strong>{{ formatCurrency(winnerSummary.cash) }}</strong></li>
              <li><span>Passive Income</span><strong>{{ formatCurrency(winnerSummary.passiveIncome) }}</strong></li>
              <li><span>Total Income</span><strong>{{ formatCurrency(winnerSummary.totalIncome) }}</strong></li>
              <li><span>Total Expenses</span><strong>{{ formatCurrency(winnerSummary.totalExpenses) }}</strong></li>
              <li><span>Cashflow</span><strong>{{ formatCurrency(winnerSummary.cashflow) }}</strong></li>
            </ul>
          </section>
          <label>
            Comment (optional)
            <textarea v-model="winnerComment" rows="3" placeholder="Add a note about the win"></textarea>
          </label>
          <footer>
            <button type="button" class="ghost" @click="close" :disabled="isLoading">Cancel</button>
            <button type="submit" :disabled="isLoading || !winnerPlayerId">
              {{ isLoading ? "Saving..." : "Confirm Winner" }}
            </button>
          </footer>
        </form>
      </div>
    </div>
  </transition>
</template>

<script>
import { mapGetters, mapState } from "vuex";
import { computeSummary } from "@/utils/cashflow";
import { playSound } from "@/utils/audio";

export default {
  name: "EndGameModal",
  computed: {
    ...mapState({
      visible: state => state.ui.endGameModal,
      isLoading: state => state.loading.game,
      formState: state => state.endGameForm
    }),
    ...mapGetters(["activeGame"]),
    players() {
      return this.activeGame?.players ?? [];
    },
    winnerPlayerId: {
      get() {
        return this.formState.winnerPlayerId || "";
      },
      set(value) {
        this.$store.dispatch("updateEndGameForm", { winnerPlayerId: value });
      }
    },
    winnerComment: {
      get() {
        return this.formState.winnerComment || "";
      },
      set(value) {
        this.$store.dispatch("updateEndGameForm", { winnerComment: value });
      }
    },
    winnerPlayer() {
      return this.players.find(player => player.id === this.winnerPlayerId) || null;
    },
    winnerSummary() {
      if (!this.winnerPlayer) return null;
      return computeSummary(this.winnerPlayer.sheetState || {});
    }
  },
  methods: {
    close() {
      this.$store.dispatch("closeEndGameModal");
    },
    formatCurrency(value) {
      return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(Number(value || 0));
    },
    async submit() {
      await this.$store.dispatch("submitEndGame");
      playSound("victory");
    }
  }
};
</script>

<style scoped lang="scss">
.end-game-modal {
  position: fixed;
  inset: 0;
  background: rgba(4, 0, 18, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 60;
  padding: 2rem;
}

.end-game-modal__panel {
  width: min(520px, 100%);
  background: rgba(18, 18, 46, 0.96);
  border: 3px solid rgba(244, 211, 94, 0.6);
  border-radius: 16px;
  padding: 1.75rem;
  color: #fdf9ff;
  box-shadow: 0 0 40px rgba(244, 211, 94, 0.2);
  font-family: "Press Start 2P", monospace;
}

header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.5rem;
}

header h3 {
  margin: 0;
  font-size: 1rem;
}

.close {
  background: none;
  border: none;
  color: rgba(244, 211, 94, 0.8);
  font-size: 1.1rem;
  cursor: pointer;
}

label {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  margin-bottom: 1.5rem;
  font-size: 0.8rem;
}

select,
textarea {
  padding: 0.6rem 0.8rem;
  background: rgba(10, 10, 28, 0.9);
  color: inherit;
  border: 2px solid rgba(244, 211, 94, 0.4);
  font-family: "Press Start 2P", monospace;
}

textarea {
  resize: vertical;
}

.winner-summary {
  border: 2px solid rgba(244, 211, 94, 0.3);
  border-radius: 12px;
  padding: 1rem 1.2rem;
  margin-bottom: 1.5rem;
}

.winner-summary h4 {
  margin: 0 0 0.8rem;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.winner-summary ul {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 0.5rem;
}

.winner-summary li {
  display: flex;
  justify-content: space-between;
  font-size: 0.75rem;
}

.winner-summary strong {
  font-size: 0.8rem;
}

footer {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
}

button {
  padding: 0.6rem 1.4rem;
  border: 2px solid rgba(244, 211, 94, 0.6);
  background: rgba(10, 10, 28, 0.9);
  color: rgba(244, 211, 94, 0.9);
  cursor: pointer;
}

button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

button.ghost {
  border-color: rgba(156, 39, 176, 0.6);
  color: rgba(156, 39, 176, 0.85);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}
</style>
