<template>
  <section class="income-record">
    <header class="income-record__header">
      <h3>Your Cashflow Day Income Record</h3>
      <div class="income-record__baseline">
        <span>Beginning Cashflow Day Income</span>
        <dollar-format-input :value="beginningCashFlowDayIncome" readonly />
      </div>
    </header>
    <div class="income-record__table-wrapper">
      <table class="income-record__table">
        <thead>
          <tr>
            <th>Business</th>
            <th>Monthly Cash Flow</th>
            <th>New Cashflow Day Income</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(investment, index) in investments" :key="index">
            <td>
              <item-input-with-mystery-meat>
                <template #input>
                  <input type="text" autocomplete="off" :value="investment.name" @input="changeInvestmentName(index, $event.target.value)" />
                </template>
                <template #right-1>
                  <a v-if="index + 1 === investments.length" class="row-action right-1" title="Add a row" @click="addInvestment">
                    <img src="@/images/add.svg" />
                  </a>
                  <a
                    v-else-if="investments.length > 12 && !investment.name && !investment.cashflow"
                    class="row-action right-1"
                    title="Remove row"
                    @click="removeInvestment(index)"
                  >
                    <img src="@/images/remove.svg" />
                  </a>
                </template>
              </item-input-with-mystery-meat>
            </td>
            <td><dollar-format-input :value="investment.cashflow" @input="changeInvestmentCashFlow(index, $event)" /></td>
            <td>
              <dollar-format-input :value="investment.cashflow ? beginningCashFlowDayIncome + getAggregateCashflow(index) : 0" readonly />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>

<script>
import DollarFormatInput from "@/components/misc/DollarFormatInput.vue";
import ItemInputWithMysteryMeat from "@/components/misc/ItemInputWithMysteryMeat.vue";
import { mapGetters, mapState, mapMutations } from "vuex";

export default {
  components: { DollarFormatInput, ItemInputWithMysteryMeat },
  computed: {
    // ...mapState("fasttrack", ["investments"]),
    ...mapGetters("fasttrack", ["beginningCashFlowDayIncome"]),
    ...mapState("fasttrack", ["investments"])
  },
  methods: {
    ...mapMutations("fasttrack", ["setInvestmentName", "setInvestmentCashflow", "addInvestment", "removeInvestment"]),
    changeInvestmentName(index, name) {
      this.setInvestmentName({ index, name });
    },
    changeInvestmentCashFlow(index, cashflow) {
      this.setInvestmentCashflow({ index, cashflow });
    },
    getAggregateCashflow(index) {
      if (!this.investments[index].cashflow) {
        return 0;
      }
      return this.investments.reduce((agg, curr, idx) => {
        if (idx <= index) {
          return agg + curr.cashflow;
        } else {
          return agg;
        }
      }, 0);
    }
  }
  //   data: () => ({ investments: [] })
};
</script>

<style scoped lang="scss">
.income-record {
  background: linear-gradient(135deg, rgba(12, 8, 34, 0.88), rgba(27, 16, 52, 0.9));
  border: 1px solid rgba(244, 211, 94, 0.25);
  border-radius: 18px;
  padding: 1.75rem;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.28);
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.income-record__header {
  display: flex;
  flex-wrap: wrap;
  gap: 1.25rem;
  align-items: center;
  justify-content: space-between;
}

.income-record__header h3 {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.95);
  font-size: 1rem;
}

.income-record__baseline {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: rgba(156, 246, 255, 0.85);
}

.income-record__baseline span {
  white-space: nowrap;
}

.income-record__baseline :deep(input) {
  width: 180px;
}

.income-record__table-wrapper {
  overflow-x: auto;
}

.income-record__table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 0.75rem;
}

.income-record__table th {
  text-align: left;
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.9);
  padding: 0 0.5rem 0.5rem;
}

.income-record__table td {
  background: linear-gradient(135deg, rgba(10, 6, 32, 0.85), rgba(18, 13, 48, 0.88));
  border: 1px solid rgba(244, 211, 94, 0.22);
  border-radius: 14px;
  padding: 0.75rem 0.9rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.58rem;
  letter-spacing: 0.04em;
  color: rgba(253, 249, 255, 0.9);
  vertical-align: middle;
}

.income-record__table td:first-child {
  min-width: 220px;
}

.income-record__table td :deep(input) {
  width: 100%;
}

/* Ensure input visibility in income record */
.income-record :deep(input[type="text"]),
.income-record :deep(input.numeric) {
  background: rgba(20, 14, 52, 0.95) !important;
  color: #f4d35e !important;
  border: 1px solid rgba(244, 211, 94, 0.3) !important;
  visibility: visible !important;
  opacity: 1 !important;
}

.row-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border-radius: 6px;
  border: 1px solid rgba(244, 211, 94, 0.35);
  background: rgba(15, 10, 40, 0.9);
  cursor: pointer;
}

.row-action img {
  width: 12px;
  height: 12px;
  filter: invert(1);
}

@media (max-width: 720px) {
  .income-record__baseline {
    flex: 1 1 100%;
    justify-content: space-between;
  }

  .income-record__baseline :deep(input) {
    width: 140px;
  }
}
</style>
