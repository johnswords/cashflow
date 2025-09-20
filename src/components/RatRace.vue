<template>
  <div class="rat-race">
    <section class="rat-race__section rat-race__section--meta">
      <rat-race-header />
    </section>

    <section class="rat-race__section rat-race__section--statement">
      <statement-area />
    </section>

    <section class="rat-race__section rat-race__section--balance">
      <balance-sheet-cash-flow />
      <balance-sheet-area />
    </section>

    <modal-window-loader />
  </div>
</template>

<script>
import RatRaceHeader from "@/components/ratrace/RatRaceHeader.vue";
import StatementArea from "@/components/ratrace/statement/StatementArea.vue";
import BalanceSheetCashFlow from "@/components/ratrace/BalanceSheetCashFlow.vue";
import BalanceSheetArea from "@/components/ratrace/balancesheet/BalanceSheetArea.vue";
import ModalWindowLoader from "@/components/application/ModalWindowLoader.vue";

export default {
  components: { RatRaceHeader, StatementArea, BalanceSheetCashFlow, BalanceSheetArea, ModalWindowLoader }
};
</script>

<style scoped lang="scss">
.rat-race {
  position: relative;
  max-width: 1100px;
  margin: 0 auto;
  padding: 2rem 0 3rem;
  display: flex;
  flex-direction: column;
  gap: 2rem;
  color: #f6f3ff;
}

.rat-race__section {
  background: linear-gradient(145deg, rgba(10, 6, 34, 0.92), rgba(4, 1, 14, 0.92));
  border: 1px solid rgba(156, 39, 176, 0.35);
  border-radius: 22px;
  box-shadow: 0 18px 40px rgba(0, 0, 0, 0.35);
  padding: 2rem 2.25rem;
  display: flex;
  flex-direction: column;
  gap: 1.75rem;
  overflow: hidden;
}

.rat-race__section--balance {
  gap: 2.25rem;
  padding-bottom: 2.5rem;
}

@media (max-width: 900px) {
  .rat-race__section {
    padding: 1.75rem 1.5rem;
    border-radius: 18px;
  }
}
</style>
