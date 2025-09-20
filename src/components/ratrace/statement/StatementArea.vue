<template>
  <div class="statement">
    <h2 class="statement__title">Income Statement</h2>
    <section id="statement-area">
      <statement-income />
      <statement-income-summary />

      <statement-expenses />
      <statement-expenses-summary />
    </section>
  </div>
</template>

<script>
import StatementIncome from "./StatementIncome.vue";
import StatementIncomeSummary from "./StatementIncomeSummary.vue";
import StatementExpenses from "./StatementExpenses.vue";
import StatementExpensesSummary from "./StatementExpensesSummary.vue";

export default {
  components: {
    StatementIncome,
    StatementIncomeSummary,
    StatementExpenses,
    StatementExpensesSummary
  }
};
</script>

<style scoped lang="scss">
.statement {
  display: flex;
  flex-direction: column;
  gap: 1.75rem;
}

.statement__title {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 1.1rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.9);
}

::v-deep #statement-area {
  display: flex;
  flex-direction: column;
  gap: 1.75rem;
}

::v-deep #income,
::v-deep #expenses {
  background: rgba(13, 10, 38, 0.92);
  border: 1px solid rgba(244, 211, 94, 0.2);
  border-radius: 18px;
  padding: 1.5rem;
}

::v-deep #income-summary,
::v-deep #expense-summary {
  display: flex;
  flex-direction: column;
  gap: 1.1rem;
  background: rgba(13, 10, 38, 0.92);
  border: 1px solid rgba(244, 211, 94, 0.25);
  border-radius: 18px;
  padding: 1.5rem;
  font-family: "Press Start 2P", monospace;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  font-size: 0.65rem;
}

::v-deep #income-summary sub,
::v-deep #expense-summary sub {
  text-transform: none;
  font-size: 0.6rem;
  opacity: 0.6;
}

::v-deep .line-inputs {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 0.75rem;
}

::v-deep .line-inputs thead th {
  font-family: "Press Start 2P", monospace;
  text-transform: uppercase;
  font-size: 0.6rem;
  letter-spacing: 0.1em;
  color: rgba(244, 211, 94, 0.75);
  text-align: left;
  padding-bottom: 0.6rem;
  border-bottom: 1px solid rgba(244, 211, 94, 0.3);
}

::v-deep .line-input,
::v-deep .blank-line-input {
  background: rgba(14, 11, 44, 0.9);
  border: 1px solid rgba(244, 211, 94, 0.2);
  border-radius: 14px;
}

::v-deep .line-input td,
::v-deep .blank-line-input td {
  padding: 0.75rem 1rem;
  vertical-align: middle;
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  letter-spacing: 0.05em;
}

::v-deep .line-input label {
  color: rgba(156, 246, 255, 0.85);
  letter-spacing: 0.08em;
  text-transform: uppercase;
  margin-right: 1rem;
}

::v-deep #income-summary,
::v-deep #expense-summary {
  min-height: auto;
}
</style>
