<template>
  <div class="player-sheet" v-if="player">
    <header class="player-sheet__header">
      <div class="player-sheet__identity">
        <span class="player-sheet__tag">Player</span>
        <h1 class="player-sheet__name">{{ player.name }}</h1>
        <span class="player-sheet__color" :style="{ backgroundColor: player.color }">{{ player.color }}</span>
      </div>
      <div class="player-sheet__controls">
        <audio-toggle />
        <button class="ghost" @click="backToGame" :disabled="isSaving">Back to Game</button>
        <button class="ghost" @click="toggleSheet">Switch Sheet</button>
        <button @click="saveChanges" :disabled="isSaving">Save &amp; Return</button>
      </div>
    </header>

    <section class="player-sheet__stats" v-if="summary">
      <div class="player-sheet__stat">
        <span>Passive Income</span>
        <strong>{{ formatCurrency(summary.passiveIncome) }}</strong>
      </div>
      <div class="player-sheet__stat">
        <span>Total Income</span>
        <strong>{{ formatCurrency(summary.totalIncome) }}</strong>
      </div>
      <div class="player-sheet__stat">
        <span>Total Expenses</span>
        <strong>{{ formatCurrency(summary.totalExpenses) }}</strong>
      </div>
      <div class="player-sheet__stat" :class="{ positive: summary.cashflow >= 0, negative: summary.cashflow < 0 }">
        <span>Cashflow</span>
        <strong>{{ formatCurrency(summary.cashflow) }}</strong>
      </div>
    </section>

    <main class="player-sheet__content">
      <div class="player-sheet__canvas">
        <component :is="sheetComponent" />
      </div>
    </main>

    <footer class="player-sheet__footer">
      <button class="ghost" @click="discardChanges" :disabled="isSaving">Cancel Changes</button>
      <span v-if="isSaving" class="saving-indicator">Saving...</span>
      <span v-if="error" class="error-indicator">{{ error }}</span>
    </footer>

    <transition name="fade">
      <div v-if="showConfirmModal" class="confirm-modal">
        <div class="confirm-modal__panel">
          <h3>Confirm Changes</h3>
          <p v-if="!pendingDiff.changes.length">No changes detected.</p>
          <ul v-else class="confirm-modal__diff-list">
            <li v-for="change in pendingDiff.changes" :key="change.path">
              <span class="diff-path">{{ change.path }}</span>
              <span class="diff-before">{{ formatValue(change.before) }}</span>
              <span class="diff-arrow">→</span>
              <span class="diff-after">{{ formatValue(change.after) }}</span>
            </li>
          </ul>
          <label
            v-if="pendingDiff.changes.length"
            class="correction-toggle"
            :class="{ locked: pendingAuditContext?.type === 'correction' }"
          >
            <input
              type="checkbox"
              :checked="isCorrection"
              @change="toggleCorrection"
              :disabled="pendingAuditContext?.type === 'correction'"
            />
            <span>Log this as a correction</span>
          </label>
          <footer class="confirm-modal__actions">
            <button class="ghost" @click="cancelConfirm" :disabled="isSaving">Cancel</button>
            <button @click="confirmSave" :disabled="isSaving">Confirm Save</button>
          </footer>
        </div>
      </div>
    </transition>
  </div>
  <div v-else class="player-sheet__empty">
    <p>No player selected.</p>
    <button @click="backToGame">Back to Game</button>
  </div>
</template>

<script>
import { mapState, mapGetters } from "vuex";
import RatRace from "@/components/RatRace.vue";
import FastTrack from "@/components/FastTrack.vue";
import { diffSheets } from "@/utils/diff";
import { computeSummary } from "@/utils/cashflow";
import { playSound } from "@/utils/audio";
import AudioToggle from "@/components/app/AudioToggle.vue";

export default {
  name: "PlayerSheetView",
  components: { RatRace, FastTrack, AudioToggle },
  data() {
    return {
      showConfirmModal: false,
      pendingDiff: { changes: [], fieldPaths: [], beforeSnapshot: {}, afterSnapshot: {} },
      markAsCorrection: false
    };
  },
  computed: {
    ...mapState({
      displaySheet: state => state.displaySheet,
      isSaving: state => state.loading.playerSave,
      error: state => state.error,
      baseline: state => state.activeSheetBaseline
    }),
    ...mapGetters(["activePlayer", "currentSheetState", "pendingAuditContext"]),
    player() {
      return this.activePlayer;
    },
    sheetComponent() {
      return this.displaySheet === "Fast Track" ? "FastTrack" : "RatRace";
    },
    summary() {
      if (!this.player) return null;
      return computeSummary(this.currentSheetState);
    },
    isCorrection() {
      if (this.pendingAuditContext?.type === "correction") return true;
      return this.markAsCorrection;
    },
    auditEntryType() {
      return this.isCorrection ? "correction" : "turn";
    }
  },
  watch: {
    pendingAuditContext: {
      immediate: true,
      handler(context) {
        this.markAsCorrection = context?.type === "correction";
      }
    }
  },
  methods: {
    backToGame() {
      this.$store.dispatch("navigate", "game-screen");
      this.$store.dispatch("clearAuditContext");
    },
    toggleSheet() {
      const next = this.displaySheet === "Rat Race" ? "Fast Track" : "Rat Race";
      this.$store.commit("SET_DISPLAY_SHEET", next);
    },
    async saveChanges() {
      const baseline = this.baseline || {};
      const current = this.currentSheetState || {};
      const diff = diffSheets(baseline, current);

      if (!diff.changes.length) {
        this.$store.dispatch("clearAuditContext");
        this.backToGame();
        return;
      }

      this.pendingDiff = diff;
      this.showConfirmModal = true;
    },
    discardChanges() {
      this.$store.dispatch("hydrateActivePlayer");
      this.backToGame();
    },
    cancelConfirm() {
      this.showConfirmModal = false;
      this.pendingDiff = { changes: [], fieldPaths: [], beforeSnapshot: {}, afterSnapshot: {} };
    },
    formatValue(value) {
      if (value === null || value === undefined) return "—";
      if (typeof value === "object") {
        try {
          return JSON.stringify(value);
        } catch (error) {
          return String(value);
        }
      }
      return String(value);
    },
    async confirmSave() {
      const audit = {
        entryType: this.auditEntryType,
        fieldPaths: this.pendingDiff.fieldPaths.length ? this.pendingDiff.fieldPaths : ["sheet"],
        beforeSnapshot: this.pendingDiff.beforeSnapshot,
        afterSnapshot: this.pendingDiff.afterSnapshot,
        originEntryId: this.pendingAuditContext?.originEntryId
      };

      try {
        await this.$store.dispatch("savePlayerSheet", { audit });
        this.showConfirmModal = false;
        this.pendingDiff = { changes: [], fieldPaths: [], beforeSnapshot: {}, afterSnapshot: {} };
        playSound("save");
        this.backToGame();
      } catch (error) {
        // error state handled via Vuex
      }
    },
    toggleCorrection(event) {
      if (this.pendingAuditContext?.type === "correction") {
        this.markAsCorrection = true;
        return;
      }
      this.markAsCorrection = event.target.checked;
    },
    formatCurrency(value) {
      return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(Number(value || 0));
    }
  }
};
</script>

<style scoped lang="scss">
.player-sheet {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: radial-gradient(circle at top left, #14002a 0%, #05010a 60%, #010006 100%);
  color: #fdf9ff;
}

.player-sheet__header,
.player-sheet__footer {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem 3rem 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-family: "Press Start 2P", monospace;
}

.player-sheet__footer {
  padding: 1.5rem 3rem 2rem;
  border-top: 1px solid rgba(244, 211, 94, 0.18);
}

.player-sheet__identity {
  display: flex;
  align-items: center;
  gap: 1.25rem;
}

.player-sheet__tag {
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
  color: #9cf6ff;
}

.player-sheet__name {
  margin: 0;
  font-size: 2.25rem;
  letter-spacing: 0.08em;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.45);
}

.player-sheet__color {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 94px;
  padding: 0.4rem 0.8rem;
  border-radius: 999px;
  border: 2px solid rgba(255, 255, 255, 0.75);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  font-size: 0.75rem;
  font-family: "Press Start 2P", monospace;
  color: #ffffff;
  box-shadow: 0 0 18px rgba(255, 255, 255, 0.15);
}

.player-sheet__controls {
  display: flex;
  align-items: center;
  gap: 1.2rem;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.player-sheet__controls button,
.player-sheet__footer button,
.confirm-modal__actions button {
  padding: 0.65rem 1.6rem;
  border-radius: 12px;
  border: 2px solid rgba(244, 211, 94, 0.65);
  background: linear-gradient(135deg, rgba(14, 12, 40, 0.95), rgba(26, 18, 52, 0.9));
  color: rgba(244, 211, 94, 0.92);
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  letter-spacing: 0.06em;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease, border-color 0.15s ease;
}

.player-sheet__controls button:hover,
.player-sheet__footer button:hover,
.confirm-modal__actions button:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 18px rgba(244, 211, 94, 0.25);
}

.player-sheet__controls button.ghost,
.player-sheet__footer button.ghost,
.confirm-modal__actions .ghost {
  border-color: rgba(156, 39, 176, 0.6);
  color: rgba(208, 170, 255, 0.9);
}

.player-sheet__controls .audio-toggle {
  border-radius: 50%;
  width: 44px;
  height: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 2px solid rgba(244, 211, 94, 0.5);
  background: rgba(10, 10, 28, 0.8);
  font-size: 1.1rem;
}

.player-sheet__stats {
  width: 100%;
  max-width: 1040px;
  margin: 0 auto 1.25rem;
  padding: 0 2rem;
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
}

.player-sheet__stat {
  background: rgba(13, 10, 34, 0.88);
  border: 1px solid rgba(244, 211, 94, 0.2);
  border-radius: 14px;
  padding: 1rem 1.2rem;
  display: flex;
  flex-direction: column;
  gap: 0.45rem;
  font-family: "Press Start 2P", monospace;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-size: 0.6rem;
}

.player-sheet__stat strong {
  font-size: 1rem;
  letter-spacing: 0.04em;
}

.player-sheet__stat.positive strong {
  color: #9cff94;
}

.player-sheet__stat.negative strong {
  color: #ff8a80;
}

.player-sheet__content {
  flex: 1;
  width: 100%;
  padding: 0 2.5rem 2.5rem;
  display: flex;
  justify-content: center;
}

.player-sheet__canvas {
  width: min(100%, 1040px);
  box-sizing: border-box;
  margin: 0 auto;
  padding: 2.25rem 2rem 2.5rem;
  background: rgba(8, 5, 24, 0.9);
  border: 1px solid rgba(156, 39, 176, 0.35);
  border-radius: 22px;
  box-shadow: 0 18px 48px rgba(0, 0, 0, 0.35);
  display: flex;
  flex-direction: column;
  gap: 2rem;
  overflow: hidden;
}

@media (max-width: 900px) {
  .player-sheet__content {
    padding: 0 2rem 2rem;
  }

  .player-sheet__stats {
    padding: 0 2rem;
  }
}

@media (max-width: 768px) {
  .player-sheet__content {
    padding: 0 1.25rem 1.75rem;
  }

  .player-sheet__canvas {
    padding: 1.75rem 1.25rem 2rem;
    border-radius: 18px;
  }

  .player-sheet__stats {
    padding: 0 1.25rem;
  }
}

.player-sheet__footer {
  gap: 1rem;
}

.saving-indicator,
.error-indicator {
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
}

.saving-indicator {
  color: #f4d35e;
}

.error-indicator {
  color: #ff8a80;
}

.confirm-modal {
  position: fixed;
  inset: 0;
  background: rgba(4, 0, 18, 0.88);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 50;
  padding: 2rem;
}

.confirm-modal__panel {
  width: min(640px, 100%);
  background: rgba(18, 18, 46, 0.95);
  border: 3px solid rgba(244, 211, 94, 0.55);
  border-radius: 16px;
  padding: 1.75rem;
  color: #fdf9ff;
  box-shadow: 0 0 30px rgba(244, 211, 94, 0.25);
}

.confirm-modal__panel h3 {
  font-family: "Press Start 2P", monospace;
  margin: 0 0 1rem;
  font-size: 1rem;
}

.confirm-modal__panel p {
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  opacity: 0.8;
  margin-bottom: 1rem;
}

.confirm-modal__diff-list {
  list-style: none;
  padding: 0;
  margin: 0 0 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
}

.confirm-modal__diff-list li {
  display: grid;
  grid-template-columns: 2fr 2fr auto 2fr;
  gap: 0.5rem;
  align-items: center;
}

.diff-path {
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #9cf6ff;
}

.diff-before {
  color: rgba(255, 138, 128, 0.9);
}

.diff-after {
  color: rgba(156, 255, 148, 0.9);
}

.diff-arrow {
  text-align: center;
  opacity: 0.6;
}

.confirm-modal__actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
}

.confirm-modal__actions .correction-toggle {
  margin-right: auto;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
}

.confirm-modal__actions .correction-toggle input {
  transform: scale(1.2);
}

.confirm-modal__actions .correction-toggle.locked {
  opacity: 0.65;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}

.player-sheet__content ::v-deep input[type="text"],
.player-sheet__content ::v-deep input[type="number"],
.player-sheet__content ::v-deep input[type="tel"],
.player-sheet__content ::v-deep select,
.player-sheet__content ::v-deep textarea {
  background: rgba(20, 14, 52, 0.9);
  border: 1px solid rgba(244, 211, 94, 0.25);
  border-radius: 10px;
  color: #fdf9ff;
  padding: 0.55rem 0.8rem;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.player-sheet__content ::v-deep input[type="text"]:focus,
.player-sheet__content ::v-deep input[type="number"]:focus,
.player-sheet__content ::v-deep select:focus,
.player-sheet__content ::v-deep textarea:focus {
  outline: none;
  border-color: rgba(244, 211, 94, 0.8);
  box-shadow: 0 0 0 2px rgba(244, 211, 94, 0.25);
}

.player-sheet__content ::v-deep sub {
  color: rgba(255, 255, 255, 0.6);
}

.player-sheet__content ::v-deep table {
  border-color: rgba(244, 211, 94, 0.25) !important;
}
</style></style>
