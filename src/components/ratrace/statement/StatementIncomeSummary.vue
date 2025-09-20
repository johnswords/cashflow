<template>
  <div id="income-summary">
    <div id="auditor-area">
      <title-input :value="auditor" @input="changeAuditor($event)" :tabindex="3">Auditor</title-input>
      <sub>Person on your right</sub>
    </div>
    <div id="passive-income-area">
      <div class="passive-income-area">
        <label>Passive Income =</label>
        <dollar-format-input id="passive-income" :value="passiveIncome" readonly />
      </div>
      <sub>(Cash flows from Interest + Dividends + Real Estate + Businesses</sub>
    </div>
    <div class="total-io">
      <label for="total-income">Total Income:</label>
      <dollar-format-input id="total-income" :value="totalIncome" readonly />
    </div>
  </div>
</template>

<script>
import { mapGetters, mapState, mapMutations } from "vuex";
import DollarFormatInput from "@/components/misc/DollarFormatInput.vue";
import TitleInput from "@/components/misc/TitleInput.vue";

export default {
  components: { DollarFormatInput, TitleInput },
  computed: {
    ...mapState("meta", ["auditor"]),
    ...mapGetters(["passiveIncome", "totalIncome"])
  },
  methods: {
    ...mapMutations("meta", ["changeAuditor"])
  }
};
</script>

<style scoped lang="scss">
#income-summary {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

#auditor-area {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

#auditor-area sub {
  text-align: left;
  font-size: 0.6rem;
  opacity: 0.6;
  font-family: "Press Start 2P", monospace;
  text-transform: none;
}

#passive-income-area {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.passive-income-area {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.passive-income-area label {
  flex: 0 0 auto;
  color: rgba(156, 246, 255, 0.85);
}

.passive-income-area :deep(input) {
  width: 100%;
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

.total-io sub {
  display: block;
  color: rgba(255, 255, 255, 0.5);
  font-size: 0.55rem;
  text-transform: none;
}
</style>
