<template>
  <div class="player-sheet" v-if="player">
    <header class="player-sheet__header">
      <div>
        <h2>{{ player.name }}</h2>
        <p>Color: <span :style="{ color: player.color }">{{ player.color }}</span></p>
      </div>
      <div class="player-sheet__controls">
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

export default {
  name: "PlayerSheetView",
  components: { RatRace, FastTrack },
  computed: {
    ...mapState({
      displaySheet: state => state.displaySheet,
      isSaving: state => state.loading.playerSave,
      error: state => state.error
    }),
    ...mapGetters(["activePlayer"]),
    player() {
      return this.activePlayer;
    },
    sheetComponent() {
      return this.displaySheet === "Fast Track" ? "FastTrack" : "RatRace";
    }
  },
  methods: {
    backToGame() {
      this.$store.dispatch("navigate", "game-screen");
    },
    toggleSheet() {
      const next = this.displaySheet === "Rat Race" ? "Fast Track" : "Rat Race";
      this.$store.commit("SET_DISPLAY_SHEET", next);
    },
    async saveChanges() {
      const audit = {
        entryType: "turn",
        fieldPaths: ["sheet"],
        beforeSnapshot: {},
        afterSnapshot: {}
      };
      try {
        await this.$store.dispatch("savePlayerSheet", { audit });
        this.backToGame();
      } catch (error) {
        // error state displayed via store
      }
    },
    discardChanges() {
      this.$store.dispatch("hydrateActivePlayer");
      this.backToGame();
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
