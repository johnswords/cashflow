<template>
  <div id="assets">
    <h3 class="column-title-bar">Assets</h3>
    <div id="asset-list">
      <div class="line-input">
        <label for="savings">Savings:</label>
        <dollar-format-input :value="savings" @input="changeSavings($event)" />
      </div>
      <div class="line-input all-text">
        <div>Stocks/Mutual's/CDs</div>
        <div>No. of Shares:</div>
        <div>Cost/Share:</div>
      </div>
      <stock-mutual-cd-asset-row v-for="(_, index) in stocks" :key="'stocks-' + index" :index="index" />
      <div class="line-input all-text">
        <div>Real Estate:</div>
        <div>Down Pay:</div>
        <div>Cost:</div>
      </div>
      <real-estate-asset-row v-for="(_, index) in realEstate" :key="'real-assets-' + index" :index="index" />
      <div class="line-input all-text">
        <div>Business:</div>
        <div>Down Pay:</div>
        <div>Cost:</div>
      </div>
      <business-asset-row v-for="(_, index) in businesses" :key="'business-assets-' + index" :index="index" />
    </div>
  </div>
</template>

<script>
import { mapState, mapMutations } from "vuex";
import DollarFormatInput from "@/components/misc/DollarFormatInput.vue";
import StockMutualCdAssetRow from "./assets/StockMutualCdAssetRow.vue";
import RealEstateAssetRow from "./assets/RealEstateAssetRow.vue";
import BusinessAssetRow from "./assets/BusinessAssetRow.vue";

export default {
  components: { DollarFormatInput, StockMutualCdAssetRow, RealEstateAssetRow, BusinessAssetRow },
  computed: {
    ...mapState("assets", ["savings"]),
    ...mapState("investments", ["stocks", "realEstate", "businesses"])
  },
  methods: {
    ...mapMutations("assets", ["changeSavings"])
  }
};
</script>

<style scoped lang="scss">
#assets {
  grid-area: assets;
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

#asset-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

#asset-list > * {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
  background: linear-gradient(135deg, rgba(12, 8, 34, 0.9), rgba(18, 13, 48, 0.9));
  border: 1px solid rgba(244, 211, 94, 0.22);
  border-radius: 16px;
  padding: 0.85rem 1.1rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  letter-spacing: 0.06em;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.25);
}

#asset-list > * > * {
  flex: 1 1 160px;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  white-space: normal;
}

#asset-list > * > :first-child {
  flex: 1 1 220px;
}

#asset-list > .all-text {
  justify-content: space-between;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.88);
  align-items: center;
}

#asset-list ::v-deep input[type="text"],
#asset-list ::v-deep input.numeric {
  width: 100%;
  background: rgba(20, 14, 52, 0.95) !important;
  color: #f4d35e !important;
  border: 1px solid rgba(244, 211, 94, 0.3) !important;
  visibility: visible !important;
  opacity: 1 !important;
}

#asset-list label {
  color: rgba(156, 246, 255, 0.9);
  text-transform: uppercase;
}

#asset-list > .all-text > div {
  flex: 1 1 180px;
  white-space: nowrap;
}

@media (max-width: 720px) {
  #asset-list > * {
    gap: 0.6rem;
  }

  #asset-list > * > * {
    flex: 1 1 100%;
  }

  #asset-list > * > :first-child {
    flex-basis: 100%;
  }
}
</style>
