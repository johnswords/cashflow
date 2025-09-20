<template>
  <div id="liabilities">
    <h3 class="column-title-bar">Liabilities</h3>

    <div class="liability-items">
      <!-- Home Mortgage -->
      <div class="liability-row">
        <label class="liability-label">Home Mortgage:</label>
        <dollar-format-input class="liability-input" :value="liabilities.mortgage" @input="changeMortgage($event)" />
      </div>

      <!-- School Loans -->
      <div class="liability-row">
        <label class="liability-label">School Loans:</label>
        <dollar-format-input class="liability-input" :value="liabilities.schoolLoan" @input="changeSchoolLoan($event)" />
      </div>

      <!-- Car Loans -->
      <div class="liability-row">
        <label class="liability-label">Car Loans:</label>
        <dollar-format-input class="liability-input" :value="liabilities.carLoan" @input="changeCarLoan($event)" />
      </div>

      <!-- Credit Cards -->
      <div class="liability-row">
        <label class="liability-label">Credit Cards:</label>
        <dollar-format-input class="liability-input" :value="liabilities.creditCard" @input="changeCreditCard($event)" />
      </div>

      <!-- Retail Debt -->
      <div class="liability-row">
        <label class="liability-label">Retail Debt:</label>
        <dollar-format-input class="liability-input" :value="liabilities.retail" @input="changeRetail($event)" />
      </div>

      <!-- Real Estate Mortgages (only shows when there's data) -->
      <template v-if="hasRealEstate">
        <div class="section-header">RE Mortgage</div>
        <div v-for="(property, index) in realEstateWithMortgage" :key="'re-' + index" class="liability-row">
          <label class="liability-label">{{ property.name || `Property ${index + 1}` }}:</label>
          <dollar-format-input class="liability-input" :value="property.mortgage" @input="changeRealEstateMortgage({ index: property.originalIndex, value: $event })" />
        </div>
      </template>

      <!-- Business Liabilities (only shows when there's data) -->
      <template v-if="hasBusinesses">
        <div class="section-header">Business Liability</div>
        <div v-for="(business, index) in businessesWithLiability" :key="'biz-' + index" class="liability-row">
          <label class="liability-label">{{ business.name || `Business ${index + 1}` }}:</label>
          <dollar-format-input class="liability-input" :value="business.liability" @input="changeBusinessLiability({ index: business.originalIndex, value: $event })" />
        </div>
      </template>

      <!-- Bank Loan -->
      <div class="liability-row">
        <label class="liability-label">Bank Loan:</label>
        <dollar-format-input class="liability-input" :value="liabilities.bankLoan" @input="changeBankLoan($event)" />
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapMutations } from "vuex";
import DollarFormatInput from "@/components/misc/DollarFormatInput.vue";

export default {
  components: { DollarFormatInput },
  computed: {
    ...mapState(["liabilities"]),
    ...mapState("investments", ["realEstate", "businesses"]),
    hasRealEstate() {
      return this.realEstate && this.realEstate.some(p => p.mortgage > 0 || p.name);
    },
    hasBusinesses() {
      return this.businesses && this.businesses.some(b => b.liability > 0 || b.name);
    },
    realEstateWithMortgage() {
      return this.realEstate
        .map((property, index) => ({ ...property, originalIndex: index }))
        .filter(p => p.mortgage > 0 || p.name);
    },
    businessesWithLiability() {
      return this.businesses
        .map((business, index) => ({ ...business, originalIndex: index }))
        .filter(b => b.liability > 0 || b.name);
    }
  },
  methods: {
    ...mapMutations("liabilities", [
      "changeMortgage",
      "changeSchoolLoan",
      "changeCarLoan",
      "changeCreditCard",
      "changeRetail",
      "changeBankLoan"
    ]),
    ...mapMutations("investments", [
      "changeRealEstateMortgage",
      "changeBusinessLiability"
    ])
  }
};
</script>

<style scoped lang="scss">
#liabilities {
  grid-area: liabilities;
  background: rgba(13, 10, 38, 0.98);
  border: 1px solid rgba(244, 211, 94, 0.2);
  border-radius: 18px;
  padding: 1.5rem;
  position: relative;
  z-index: 10;
  isolation: isolate;
}

.column-title-bar {
  margin: 0 0 1.25rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: rgba(156, 246, 255, 0.85);
}

.liability-items {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.liability-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  background: rgba(14, 11, 44, 0.95);
  border: 1px solid rgba(244, 211, 94, 0.25);
  border-radius: 14px;
  padding: 0.85rem 1.1rem;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  position: relative;
  z-index: 1;
}

.liability-label {
  flex: 0 0 40%;
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.95);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.liability-input {
  flex: 1;
}

.liability-input ::v-deep input {
  width: 100%;
  background: rgba(20, 14, 52, 0.95);
  color: #f4d35e;
  border: 1px solid rgba(244, 211, 94, 0.3);
  border-radius: 8px;
  padding: 0.6rem 0.8rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  letter-spacing: 0.05em;
}

.liability-input ::v-deep input:focus {
  border-color: rgba(244, 211, 94, 0.8);
  background: rgba(28, 20, 68, 0.95);
  box-shadow: 0 0 12px rgba(244, 211, 94, 0.3);
}

.section-header {
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.75);
  margin-top: 0.5rem;
  padding-left: 0.5rem;
}

@media (max-width: 720px) {
  .liability-row {
    flex-direction: column;
    align-items: stretch;
    gap: 0.5rem;
  }

  .liability-label {
    flex: none;
  }
}
</style>