<template>
  <section class="win-card">
    <h3 class="win-card__title">How to Win!</h3>
    <div class="win-card__rows">
      <div class="win-card__row">
        <span class="win-card__label">Your Beginning CASHFLOW Day Income</span>
        <div class="win-card__value">
          <span class="win-card__symbol">=</span>
          <dollar-format-input :value="beginningCashFlowDayIncome" readonly />
        </div>
      </div>
      <div class="win-card__row">
        <span class="win-card__label">Fast Track Cash Flow Needed to Win</span>
        <div class="win-card__value">
          <span class="win-card__symbol">+</span>
          <dollar-format-input :value="50000" readonly />
        </div>
      </div>
      <div class="win-card__row">
        <span class="win-card__label">Your New CASHFLOW Day Income Goal to Win</span>
        <div class="win-card__value">
          <span class="win-card__symbol">=</span>
          <dollar-format-input :value="beginningCashFlowDayIncome + 50000" readonly />
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import DollarFormatInput from "@/components/misc/DollarFormatInput.vue";
import { mapGetters } from "vuex";

export default {
  components: { DollarFormatInput },
  computed: {
    ...mapGetters("fasttrack", ["beginningCashFlowDayIncome"])
  }
};
</script>

<style scoped lang="scss">
.win-card {
  background: linear-gradient(135deg, rgba(12, 8, 34, 0.88), rgba(27, 16, 52, 0.9));
  border: 1px solid rgba(244, 211, 94, 0.25);
  border-radius: 18px;
  padding: 1.75rem;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.26);
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.win-card__title {
  margin: 0;
  text-align: center;
  font-family: "Press Start 2P", monospace;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.95);
  font-size: 1rem;
}

.win-card__rows {
  display: flex;
  flex-direction: column;
  gap: 1.15rem;
}

.win-card__row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 1rem;
  justify-content: space-between;
}

.win-card__label {
  flex: 1 1 260px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: rgba(156, 246, 255, 0.9);
  line-height: 1.5;
}

.win-card__value {
  flex: 0 1 220px;
  display: flex;
  align-items: center;
  gap: 0.65rem;
  font-family: "Press Start 2P", monospace;
  color: rgba(244, 211, 94, 0.9);
}

.win-card__symbol {
  font-size: 0.8rem;
}

.win-card__value :deep(input) {
  width: 100%;
}

@media (max-width: 640px) {
  .win-card__value {
    flex: 1 1 100%;
  }
}
</style>
