<template>
  <section id="balance-sheet-area">
    <balance-sheet-assets />
    <balance-sheet-liabilities />
  </section>
</template>

<script>
import BalanceSheetAssets from "./BalanceSheetAssets.vue";
import BalanceSheetLiabilities from "./BalanceSheetLiabilities.vue";

export default {
  components: {
    BalanceSheetAssets,
    BalanceSheetLiabilities
  }
};
</script>

<style scoped lang="scss">
#balance-sheet-area {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 1.75rem;
}

@media (min-width: 1300px) {
  #balance-sheet-area {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
