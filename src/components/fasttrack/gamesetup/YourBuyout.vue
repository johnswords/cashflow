<template>
  <section class="buyout">
    <div class="buyout__meta">
      <div class="player-chip" v-if="playerName">
        <span class="player-chip__label">Player</span>
        <span class="player-chip__value">{{ playerName }}</span>
      </div>
      <div class="buyout__auditor">
        <title-input :value="auditor" @input="changeAuditor($event)" :tabindex="3">Auditor</title-input>
        <span class="buyout__auditor-hint">Person on your right</span>
      </div>
    </div>

    <div class="buyout__card">
      <h3 class="buyout__title">Your Buyout</h3>
      <div class="buyout__rows">
        <div class="buyout__row">
          <div class="buyout__label">
            Your Passive Income (from other side)
            <small>(Rounded to nearest thousand dollars)</small>
          </div>
          <div class="buyout__value">
            <span class="buyout__symbol">=</span>
            <dollar-format-input :value="beginningCashFlowDayIncome / 100" readonly />
          </div>
        </div>
        <div class="buyout__row">
          <div class="buyout__label">Buyout Multiple</div>
          <div class="buyout__value">
            <span class="buyout__symbol">×</span>
            <span class="buyout__constant">100</span>
          </div>
        </div>
        <div class="buyout__row">
          <div class="buyout__label">Your Beginning CASHFLOW Day Income</div>
          <div class="buyout__value">
            <span class="buyout__symbol">=</span>
            <dollar-format-input :value="beginningCashFlowDayIncome" readonly />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import TitleInput from "@/components/misc/TitleInput.vue";
import DollarFormatInput from "@/components/misc/DollarFormatInput.vue";
import { mapState, mapMutations, mapGetters } from "vuex";

export default {
  components: { TitleInput, DollarFormatInput },
  computed: {
    ...mapState("meta", ["auditor", "player"]),
    ...mapGetters("fasttrack", ["beginningCashFlowDayIncome"]),
    ...mapGetters(["activePlayer"]),
    playerName() {
      return this.activePlayer?.name || this.player;
    }
  },
  methods: {
    ...mapMutations("meta", ["changeAuditor"])
  }
};
</script>

<style scoped lang="scss">
.buyout {
  display: flex;
  flex-direction: column;
  gap: 1.75rem;
}

.buyout__meta {
  display: flex;
  flex-wrap: wrap;
  gap: 1.25rem;
  align-items: center;
  justify-content: space-between;
}

.player-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  font-family: "Press Start 2P", monospace;
  letter-spacing: 0.08em;
}

.player-chip__label {
  font-size: 0.68rem;
  text-transform: uppercase;
  color: rgba(156, 246, 255, 0.85);
}

.player-chip__value {
  padding: 0.35rem 0.85rem;
  border-radius: 999px;
  border: 2px solid rgba(156, 39, 176, 0.4);
  background: rgba(13, 10, 34, 0.85);
  color: rgba(244, 211, 94, 0.9);
}

.buyout__auditor {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  min-width: 260px;
}

.buyout__auditor-hint {
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: rgba(255, 255, 255, 0.55);
}

.buyout__card {
  background: linear-gradient(135deg, rgba(12, 8, 34, 0.88), rgba(27, 16, 52, 0.9));
  border: 1px solid rgba(244, 211, 94, 0.25);
  border-radius: 18px;
  padding: 1.75rem;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.28);
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.buyout__title {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  text-align: center;
  color: rgba(244, 211, 94, 0.95);
  font-size: 1rem;
}

.buyout__rows {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.buyout__row {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  justify-content: space-between;
  align-items: flex-start;
}

.buyout__label {
  flex: 1 1 260px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: rgba(156, 246, 255, 0.9);
  line-height: 1.5;
}

.buyout__label small {
  display: block;
  margin-top: 0.35rem;
  font-size: 0.5rem;
  letter-spacing: 0.04em;
  color: rgba(255, 255, 255, 0.5);
  text-transform: none;
}

.buyout__value {
  flex: 0 1 220px;
  display: flex;
  align-items: center;
  gap: 0.65rem;
  font-family: "Press Start 2P", monospace;
  color: rgba(244, 211, 94, 0.9);
}

.buyout__symbol {
  font-size: 0.8rem;
}

.buyout__constant {
  font-size: 0.8rem;
}

.buyout__value :deep(input) {
  width: 100%;
}

@media (max-width: 640px) {
  .buyout__value {
    flex: 1 1 100%;
  }
}
</style>
