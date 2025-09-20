<template>
  <div class="monthly-cash-flow">
    <label class="monthly-cash-flow__label" for="monthly-cash-flow">
      Monthly Cash Flow
      <sub>(Pay Check)</sub>
    </label>
    <dollar-format-input id="monthly-cash-flow" :value="cashFlow" readonly />
  </div>
</template>

<script>
import { mapGetters } from "vuex";
import DollarFormatInput from "@/components/misc/DollarFormatInput.vue";

export default {
  components: { DollarFormatInput },
  computed: {
    ...mapGetters(["cashFlow"])
  }
};
</script>

<style scoped lang="scss">
.monthly-cash-flow {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 1rem 1.25rem;
  background: rgba(20, 14, 52, 0.92);
  border: 1px solid rgba(244, 211, 94, 0.25);
  border-radius: 14px;
}

.monthly-cash-flow__label {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: rgba(156, 246, 255, 0.85);
}

.monthly-cash-flow__label sub {
  font-size: 0.55rem;
  color: rgba(255, 255, 255, 0.6);
  text-transform: none;
}

#monthly-cash-flow {
  font-size: 1rem;
  width: 100%;
}

@media (max-width: 600px) {
  .monthly-cash-flow {
    flex-direction: column;
    align-items: flex-start;
  }

  #monthly-cash-flow {
    width: 100%;
  }
}
</style>
