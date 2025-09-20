<template>
  <div id="children-box">
    <div class="children-input">
      <label for="number-of-children">
        Number of
        <br />Children:
      </label>
      <input
        type="text"
        autocomplete="off"
        id="number-of-children"
        :value="children.numberOfChildren"
        @input="changeNumberOfChildren($event.target.value)"
        class="numeric"
      />
    </div>
    <sub>(Begin game with 0 children)</sub>
    <div class="children-input">
      <label for="per-child-expense">
        Per Child
        <br />Expense:
      </label>
      <dollar-format-input id="per-child-expense" :value="children.perChildExpense" @input="changePerChildExpense($event)" />
    </div>
  </div>
</template>

<script>
import { mapState, mapMutations } from "vuex";
import DollarFormatInput from "@/components/misc/DollarFormatInput.vue";

export default {
  components: { DollarFormatInput },
  computed: {
    ...mapState("expenses", ["children"])
  },
  methods: {
    ...mapMutations("expenses", ["changeNumberOfChildren", "changePerChildExpense"])
  }
};
</script>

<style scoped lang="scss">
#children-box {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  background: rgba(20, 14, 52, 0.9);
  border: 1px solid rgba(244, 211, 94, 0.25);
  border-radius: 16px;
  padding: 1.25rem 1.5rem;
}

.children-input {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: rgba(156, 246, 255, 0.85);
}

.children-input label {
  line-height: 1.3;
}

#children-box sub {
  grid-column: 1 / -1;
  color: rgba(255, 255, 255, 0.55);
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  text-transform: none;
}

#children-box :deep(input) {
  width: 100%;
}
</style>
