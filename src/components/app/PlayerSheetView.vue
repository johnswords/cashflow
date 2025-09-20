<template>
  <div class="player-sheet" v-if="player">
    <header class="player-sheet__header">
      <div>
        <h2>{{ player.name }}</h2>
        <p>Color: <span :style="{ color: player.color }">{{ player.color }}</span></p>
      </div>
      <div class="player-sheet__controls">
        <audio-toggle />
        <button class="ghost" @click="backToGame" :disabled="isSaving">Back to Game</button>
        <button class="ghost" @click="toggleSheet">Switch Sheet</button>
        <button @click="saveChanges" :disabled="isSaving">Save &amp; Return</button>
      </div>
    </header>

    <main class="player-sheet__content">
      <component :is="sheetComponent" />
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
    }
  }
};
</script>

<style scoped lang="scss">
.player-sheet {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: linear-gradient(160deg, #090014, #1e1440 55%, #05010a 100%);
  color: #fdf9ff;
}

.player-sheet__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid rgba(244, 211, 94, 0.2);
  font-family: "Press Start 2P", monospace;
}

.player-sheet__header h2 {
  margin: 0 0 0.4rem;
}

.player-sheet__controls button {
  margin-left: 1rem;
  padding: 0.65rem 1.4rem;
  border: 2px solid rgba(244, 211, 94, 0.7);
  background: rgba(10, 10, 28, 0.9);
  color: rgba(244, 211, 94, 0.9);
  font-family: inherit;
  cursor: pointer;
}

.player-sheet__controls .ghost {
  border-color: rgba(156, 39, 176, 0.6);
  color: rgba(156, 39, 176, 0.85);
}

.player-sheet__content {
  flex: 1;
  overflow-y: auto;
  padding: 1rem 2rem 3rem;
}

.player-sheet__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 2rem;
  border-top: 1px solid rgba(244, 211, 94, 0.2);
}

.player-sheet__footer button {
  padding: 0.6rem 1.2rem;
  border: 2px solid rgba(244, 211, 94, 0.6);
  background: rgba(10, 10, 28, 0.9);
  color: rgba(244, 211, 94, 0.9);
  font-family: "Press Start 2P", monospace;
  cursor: pointer;
}

.player-sheet__footer .ghost {
  border-color: rgba(156, 39, 176, 0.6);
  color: rgba(156, 39, 176, 0.85);
}

.saving-indicator {
  color: #f4d35e;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
}

.error-indicator {
  color: #ff8a80;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
}

.confirm-modal {
  position: fixed;
  inset: 0;
  background: rgba(4, 0, 18, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 50;
  padding: 2rem;
}

.confirm-modal__panel {
  width: min(640px, 100%);
  background: rgba(18, 18, 46, 0.95);
  border: 3px solid rgba(244, 211, 94, 0.6);
  border-radius: 16px;
  padding: 1.75rem;
  color: #fdf9ff;
  box-shadow: 0 0 30px rgba(244, 211, 94, 0.2);
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

.confirm-modal__actions button {
  padding: 0.6rem 1.4rem;
  border: 2px solid rgba(244, 211, 94, 0.6);
  background: rgba(10, 10, 28, 0.9);
  color: rgba(244, 211, 94, 0.9);
  font-family: "Press Start 2P", monospace;
  cursor: pointer;
}

.confirm-modal__actions .ghost {
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

.player-sheet__empty {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #08001a;
  gap: 1rem;
}

.player-sheet__empty button {
  padding: 0.6rem 1.5rem;
  border: 2px solid rgba(244, 211, 94, 0.6);
  background: transparent;
  color: rgba(244, 211, 94, 0.9);
  font-family: "Press Start 2P", monospace;
  cursor: pointer;
}
</style>
