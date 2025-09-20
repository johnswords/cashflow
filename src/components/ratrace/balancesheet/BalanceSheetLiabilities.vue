<template>
  <div id="liabilities">
    <h3 class="column-title-bar">Liabilities</h3>
    <table id="liability-list" class="line-inputs">
      <tbody>
        <state-connected-value-input title="Home Mortgage" category="liabilities" item="mortgage" change="changeMortgage" />
        <state-connected-value-input title="School Loans" category="liabilities" item="schoolLoan" change="changeSchoolLoan" />
        <state-connected-value-input title="Car Loans" category="liabilities" item="carLoan" change="changeCarLoan" />
        <state-connected-value-input title="Credit Cards" category="liabilities" item="creditCard" change="changeCreditCard" />
        <state-connected-value-input title="Retail Debt" category="liabilities" item="retail" change="changeRetail" />
      </tbody>
      <liability-real-estate />
      <liability-businesses />
      <tbody>
        <state-connected-value-input title="Bank Loan" category="liabilities" item="bankLoan" change="changeBankLoan" />
      </tbody>
    </table>
  </div>
</template>

<script>
import StateConnectedValueInput from "@/components/misc/StateConnectedValueInput.vue";
import LiabilityRealEstate from "./liabilities/LiabilityRealEstate.vue";
import LiabilityBusinesses from "./liabilities/LiabilityBusinesses.vue";

export default {
  components: { StateConnectedValueInput, LiabilityRealEstate, LiabilityBusinesses }
};
</script>

<style scoped lang="scss">
#liabilities {
  grid-area: liabilities;
  background: rgba(13, 10, 38, 0.92);
  border: 1px solid rgba(244, 211, 94, 0.2);
  border-radius: 18px;
  padding: 1.5rem;
}

.column-title-bar {
  margin: 0 0 1.25rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: rgba(156, 246, 255, 0.85);
}

#liability-list {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 0.75rem;
}

#liability-list tbody tr {
  background: linear-gradient(135deg, rgba(12, 8, 34, 0.9), rgba(18, 13, 48, 0.9));
  border: 1px solid rgba(244, 211, 94, 0.22);
  border-radius: 16px;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.25);
}

#liability-list tbody tr td {
  padding: 0.75rem 1rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  letter-spacing: 0.06em;
}

#liability-list tbody tr td:first-child {
  min-width: 150px;
  color: rgba(244, 211, 94, 0.85);
  text-transform: uppercase;
  white-space: normal;
}

#liability-list tbody tr td:last-child {
  width: 100%;
}

@media (max-width: 720px) {
  #liability-list tbody tr td:first-child {
    width: auto;
  }
}
</style>
