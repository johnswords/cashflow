<template>
  <div class="new-game">
    <div class="new-game__panel">
      <header class="new-game__header">
        <h2>New Game Setup</h2>
        <p>Select the roster and colors before starting.</p>
      </header>

      <form class="new-game__form" @submit.prevent="handleSubmit">
        <label class="new-game__field">
          <span>Number of Players</span>
          <select v-model.number="playerCount">
            <option v-for="n in 5" :key="n" :value="n + 1">{{ n + 1 }}</option>
          </select>
        </label>

        <div class="new-game__players">
          <div v-for="(player, index) in players" :key="player.id" class="player-card">
            <h3>Player {{ index + 1 }}</h3>
            <label>
              <span>Name</span>
              <input v-model.trim="player.name" placeholder="Enter name" />
            </label>
            <label>
              <span>Color</span>
              <select v-model="player.color">
                <option v-for="color in colorOptions(index)" :key="color" :value="color">
                  {{ color }}
                </option>
              </select>
            </label>
          </div>
        </div>

        <footer class="new-game__actions">
          <button type="button" class="ghost" @click="goBack" :disabled="isSubmitting">Back</button>
          <button type="submit" :disabled="isSubmitting || hasValidationErrors">Start Game</button>
        </footer>

        <p v-if="error" class="new-game__error">{{ error }}</p>
      </form>
    </div>
  </div>
</template>

<script>
import { nanoid } from "nanoid";
import { mapState } from "vuex";

const COLORS = ["blue", "purple", "orange", "red", "green", "yellow"];

export default {
  name: "NewGameSetup",
  data() {
    return {
      playerCount: 2,
      players: this.buildPlayers(2),
      isSubmitting: false
    };
  },
  computed: {
    ...mapState({
      error: state => state.error
    }),
    hasValidationErrors() {
      const names = this.players.map(player => player.name.trim());
      const colors = this.players.map(player => player.color);
      const uniqueNames = new Set(names.filter(Boolean));
      const uniqueColors = new Set(colors);
      const allNamesFilled = names.every(Boolean);
      return !(allNamesFilled && uniqueNames.size === this.players.length && uniqueColors.size === this.players.length);
    }
  },
  watch: {
    playerCount(newCount) {
      this.players = this.buildPlayers(newCount, this.players);
    }
  },
  methods: {
    buildPlayers(count, existing = []) {
      return Array.from({ length: count }, (_value, index) => {
        const current = existing[index] || {};
        const color = COLORS[index] || COLORS[0];
        return {
          id: current.id || nanoid(6),
          name: current.name || "",
          color: current.color || color
        };
      });
    },
    colorOptions(currentIndex) {
      const taken = new Set(this.players.map(p => p.color));
      return COLORS.filter(color => taken.has(color) ? this.players[currentIndex].color === color : true);
    },
    async handleSubmit() {
      if (this.hasValidationErrors) return;
      this.isSubmitting = true;
      try {
        await this.$store.dispatch("createGame", {
          players: this.players.map(player => ({
            name: player.name.trim(),
            color: player.color
          }))
        });
      } catch (error) {
        // Error already stored in Vuex; no-op
      } finally {
        this.isSubmitting = false;
      }
    },
    goBack() {
      this.$store.dispatch("navigate", "load-screen");
    }
  }
};
</script>

<style scoped lang="scss">
.new-game {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1a1a40, #08001a 70%);
  padding: 2rem;
  color: #f5f3ff;
}

.new-game__panel {
  width: min(960px, 100%);
  background: rgba(18, 18, 46, 0.92);
  border: 4px solid #4e54c8;
  border-radius: 16px;
  padding: 2.5rem;
  box-shadow: 0 0 32px rgba(78, 84, 200, 0.4);
}

.new-game__header h2 {
  font-family: "Press Start 2P", monospace;
  margin-bottom: 0.5rem;
}

.new-game__header p {
  opacity: 0.75;
  margin-bottom: 1.5rem;
}

.new-game__field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.new-game__field select {
  padding: 0.6rem 0.9rem;
  font-size: 1rem;
  background: #0d0c2a;
  color: inherit;
  border: 2px solid #4e54c8;
}

.new-game__players {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1.25rem;
  margin-bottom: 1.5rem;
}

.player-card {
  background: rgba(12, 12, 32, 0.85);
  border: 2px solid rgba(164, 131, 248, 0.5);
  padding: 1rem;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.player-card h3 {
  font-family: "Press Start 2P", monospace;
  font-size: 0.85rem;
  margin: 0;
}

.player-card label {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  font-size: 0.85rem;
}

.player-card input,
.player-card select {
  padding: 0.6rem 0.8rem;
  background: #0d0c2a;
  color: inherit;
  border: 2px solid rgba(164, 131, 248, 0.4);
}

.new-game__actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
}

.new-game__actions button {
  font-family: "Press Start 2P", monospace;
  padding: 0.75rem 1.8rem;
  border: 3px solid #f4d35e;
  background: #0d0c2a;
  color: #f4d35e;
  cursor: pointer;
}

.new-game__actions .ghost {
  border-color: rgba(244, 211, 94, 0.4);
  color: rgba(244, 211, 94, 0.6);
}

.new-game__actions button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.new-game__error {
  margin-top: 1.5rem;
  color: #ff8a80;
  font-family: "Press Start 2P", monospace;
  font-size: 0.85rem;
  text-align: right;
}
</style>
