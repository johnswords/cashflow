<template>
  <div class="balance-sheet-header">
    <h2 class="balance-sheet-header__title">Balance Sheet</h2>
    <monthly-cash-flow class="balance-sheet-header__cashflow" />
  </div>
</template>

<script>
import MonthlyCashFlow from "@/components/ratrace/MonthlyCashFlow.vue";

export default {
  components: { MonthlyCashFlow }
};
</script>

<style scoped lang="scss">
.balance-sheet-header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1.5rem;
}

.balance-sheet-header__title {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 1.1rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.9);
}

.balance-sheet-header__cashflow {
  flex: 1 1 260px;
  display: flex;
  justify-content: flex-end;
}

@media (max-width: 800px) {
  .balance-sheet-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .balance-sheet-header__cashflow {
    width: 100%;
    justify-content: flex-start;
  }
}
</style>
