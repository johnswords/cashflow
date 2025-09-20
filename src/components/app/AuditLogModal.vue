<template>
  <transition name="fade">
    <div v-if="visible" class="audit-modal">
      <div class="audit-modal__panel">
        <header class="audit-modal__header">
          <h3>Audit Log</h3>
          <button class="close" @click="close">✕</button>
        </header>

        <section class="audit-modal__filters" v-if="players.length">
          <label>
            Player
            <select v-model="selectedPlayerId">
              <option value="">All Players</option>
              <option v-for="player in players" :key="player.id" :value="player.id">
                {{ player.name }}
              </option>
            </select>
          </label>
        </section>

        <section v-if="entriesToDisplay.length" class="audit-modal__table-wrapper">
          <table class="audit-modal__table">
            <thead>
              <tr>
                <th>Time</th>
                <th>Player</th>
                <th>Type</th>
                <th>Fields</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="entry in entriesToDisplay" :key="entry.id">
                <td>{{ formatDate(entry.timestamp) }}</td>
                <td>{{ playerName(entry.playerId) }}</td>
                <td :class="entry.entryType">{{ entry.entryType }}</td>
                <td>
                  <ul>
                    <li v-for="field in entry.fieldPaths" :key="field">{{ field }}</li>
                  </ul>
                </td>
                <td class="actions">
                  <button @click="correct(entry)">Correct</button>
                </td>
              </tr>
            </tbody>
          </table>
        </section>
        <p v-else class="audit-modal__empty">No audit entries yet.</p>

        <footer class="audit-modal__footer">
          <button class="secondary" @click="loadMore" :disabled="isLoading || pagination.endReached">
            {{ pagination.endReached ? "No More" : isLoading ? "Loading..." : "Load More" }}
          </button>
          <button class="primary" @click="close">Close</button>
        </footer>
      </div>
    </div>
  </transition>
</template>

<script>
import { mapGetters, mapState } from "vuex";

export default {
  name: "AuditLogModal",
  data() {
    return {
      selectedPlayerId: ""
    };
  },
  computed: {
    ...mapState({
      visible: state => state.ui.auditModal,
      pagination: state => state.auditPagination,
      isLoading: state => state.loading.audit,
      activeAuditPlayerId: state => state.activeAuditPlayerId
    }),
    ...mapGetters(["auditEntries", "activeGame"]),
    entriesToDisplay() {
      if (!this.selectedPlayerId) return this.auditEntries;
      return this.auditEntries.filter(entry => entry.playerId === this.selectedPlayerId);
    },
    players() {
      return this.activeGame?.players ?? [];
    }
  },
  watch: {
    activeAuditPlayerId: {
      immediate: true,
      handler(value) {
        this.selectedPlayerId = value || "";
      }
    },
    selectedPlayerId(value) {
      this.$store.commit("SET_ACTIVE_AUDIT_PLAYER", value || null);
    }
  },
  methods: {
    formatDate(value) {
      return new Date(value).toLocaleString();
    },
    playerName(playerId) {
      return this.players.find(player => player.id === playerId)?.name || "?";
    },
    async loadMore() {
      if (this.pagination.endReached) return;
      await this.$store.dispatch("fetchAudit", { reset: false });
    },
    correct(entry) {
      this.$store.dispatch("startCorrection", entry);
    },
    close() {
      this.$store.dispatch("closeAuditLog");
    }
  }
};
</script>

<style scoped lang="scss">
.audit-modal {
  position: fixed;
  inset: 0;
  background: rgba(4, 0, 18, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 60;
  padding: 2rem;
}

.audit-modal__panel {
  width: min(960px, 100%);
  background: rgba(18, 18, 46, 0.96);
  border: 3px solid rgba(244, 211, 94, 0.6);
  border-radius: 16px;
  padding: 1.75rem;
  color: #fdf9ff;
  box-shadow: 0 0 40px rgba(244, 211, 94, 0.2);
}

.audit-modal__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
  font-family: "Press Start 2P", monospace;
}

.audit-modal__header h3 {
  margin: 0;
  font-size: 1rem;
}

.audit-modal__header .close {
  background: none;
  border: none;
  color: rgba(244, 211, 94, 0.8);
  font-size: 1.1rem;
  cursor: pointer;
}

.audit-modal__filters {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
}

.audit-modal__filters select {
  margin-left: 0.5rem;
  padding: 0.4rem 0.6rem;
  background: rgba(10, 10, 28, 0.9);
  color: inherit;
  border: 2px solid rgba(244, 211, 94, 0.4);
}

.audit-modal__table-wrapper {
  max-height: 420px;
  overflow-y: auto;
  margin-bottom: 1rem;
}

.audit-modal__table {
  width: 100%;
  border-collapse: collapse;
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
}

.audit-modal__table th,
.audit-modal__table td {
  border-bottom: 1px solid rgba(244, 211, 94, 0.15);
  padding: 0.75rem 0.6rem;
  vertical-align: top;
}

.audit-modal__table td.correction {
  color: #9cff94;
}

.audit-modal__table td.turn {
  color: rgba(244, 211, 94, 0.9);
}

.audit-modal__table td ul {
  list-style: none;
  margin: 0;
  padding: 0;
}

.audit-modal__table td ul li {
  line-height: 1.4;
}

.audit-modal__table td.actions {
  text-align: right;
}

.audit-modal__table button {
  padding: 0.4rem 0.8rem;
  border: 2px solid rgba(244, 211, 94, 0.6);
  background: rgba(10, 10, 28, 0.9);
  color: rgba(244, 211, 94, 0.9);
  font-family: inherit;
  cursor: pointer;
}

.audit-modal__table td .correction {
  color: #9cff94;
}

.audit-modal__empty {
  font-family: "Press Start 2P", monospace;
  text-align: center;
  margin: 2rem 0;
  opacity: 0.8;
}

.audit-modal__footer {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
}

.audit-modal__footer .secondary,
.audit-modal__footer .primary {
  padding: 0.6rem 1.4rem;
  border: 2px solid rgba(244, 211, 94, 0.6);
  background: rgba(10, 10, 28, 0.9);
  color: rgba(244, 211, 94, 0.9);
  font-family: "Press Start 2P", monospace;
  cursor: pointer;
}

.audit-modal__footer .secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
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
