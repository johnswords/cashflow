<template>
  <div id="expense-summary">
    <children-box />
    <div class="total-io">
      <label for="total-expenses">Total Expenses:</label>
      <dollar-format-input id="total-expenses" :value="totalExpenses" readonly />
    </div>
  </div>
</template>

<script>
import { mapGetters } from "vuex";
import DollarFormatInput from "@/components/misc/DollarFormatInput.vue";
import ChildrenBox from "./ChildrenBox.vue";

export default {
  components: { DollarFormatInput, ChildrenBox },
  computed: {
    ...mapGetters(["totalExpenses"])
  }
};
</script>

<style scoped lang="scss">
#expense-summary {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.total-io {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.total-io label {
  color: rgba(244, 211, 94, 0.85);
}

.total-io :deep(input) {
  width: 100%;
}
</style>
