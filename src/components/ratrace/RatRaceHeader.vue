<template>
  <div class="rat-race-header">
    <title-input :value="profession" @input="changeProfession($event)" :tabindex="1">Profession</title-input>
    <p class="rat-race-header__goal">
      Goal: Get out of the Rat Race and onto the Fast Track by building up your passive income so it exceeds your total expenses.
    </p>
  </div>
</template>

<script>
import TitleInput from "@/components/misc/TitleInput.vue";
import { mapState, mapMutations } from "vuex";

export default {
  components: { TitleInput },
  computed: {
    ...mapState("meta", ["profession"])
  },
  methods: {
    ...mapMutations("meta", ["changeProfession"])
  }
};
</script>

<style scoped lang="scss">
.rat-race-header {
  display: flex;
  flex-direction: column;
  gap: 1.2rem;
  padding: 1.5rem;
  background: rgba(20, 14, 52, 0.92);
  border: 1px solid rgba(244, 211, 94, 0.22);
  border-radius: 16px;
}

.rat-race-header__goal {
  margin: 0;
  font-size: 0.68rem;
  color: rgba(244, 211, 94, 0.75);
  font-family: "Press Start 2P", monospace;
  line-height: 1.6;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.rat-race-header :deep(input) {
  width: 100%;
}
</style>
