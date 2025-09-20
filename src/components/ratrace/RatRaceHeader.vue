<template>
  <div class="rat-race-header">
    <title-input :value="profession" @input="changeProfession($event)" :tabindex="1">Profession</title-input>
    <p class="rat-race-header__goal">
      Goal: To get out of the Rat Race and onto the Fast Track by building up your Passive Income to be greater than your Total Expenses
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
  gap: 1rem;
}

.rat-race-header__goal {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.72);
  font-family: "Press Start 2P", monospace;
  line-height: 1.4;
}
</style>
