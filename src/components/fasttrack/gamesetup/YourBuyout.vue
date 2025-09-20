<template>
  <section class="area">
    <div class="player-chip" v-if="playerName">
      <span class="player-chip__label">Player</span>
      <span class="player-chip__value">{{ playerName }}</span>
    </div>
    <div id="auditor-area">
      <title-input :value="auditor" @input="changeAuditor($event)" :tabindex="3">Auditor</title-input>
      <sub>Person on your right</sub>
    </div>
    <section class="title-box">
      <h3>Your Buyout</h3>
      <table>
        <tr>
          <td>Your Passive Income (from other side) <sub>(Rounded to Nearest Thousand Dollars)</sub></td>
          <td>=</td>
          <td><dollar-format-input :value="beginningCashFlowDayIncome / 100" readonly /></td>
        </tr>
        <tr>
          <td>Buyout Multiple</td>
          <td colspan="2" class="numeric">X 100</td>
        </tr>
        <tr>
          <td>Your Beginning CASHFLOW Day Income</td>
          <td>=</td>
          <td><dollar-format-input :value="beginningCashFlowDayIncome" readonly /></td>
        </tr>
      </table>
    </section>
  </section>
</template>

<script>
import TitleInput from "@/components/misc/TitleInput.vue";
import DollarFormatInput from "@/components/misc/DollarFormatInput.vue";
import { mapState, mapMutations, mapGetters } from "vuex";

export default {
  components: { TitleInput, DollarFormatInput },
  computed: {
    ...mapState("meta", ["auditor", "player"]),
    ...mapGetters("fasttrack", ["beginningCashFlowDayIncome"]),
    ...mapGetters(["activePlayer"]),
    playerName() {
      return this.activePlayer?.name || this.player;
    }
  },
  methods: {
    ...mapMutations("meta", ["changeAuditor"])
  }
};
</script>

<style scoped lang="scss">
.area {
  display: flex;
  flex-direction: column;
  align-content: space-between;
  gap: 2.5rem;
}

.player-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  font-family: "Press Start 2P", monospace;
  letter-spacing: 0.08em;
}

.player-chip__label {
  font-size: 0.7rem;
  text-transform: uppercase;
  color: rgba(156, 246, 255, 0.85);
}

.player-chip__value {
  padding: 0.35rem 0.75rem;
  border-radius: 999px;
  border: 2px solid rgba(156, 39, 176, 0.4);
  background: rgba(13, 10, 34, 0.85);
}

#auditor-area {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
</style>

<style lang="scss">
.title-box {
  border: 1px solid black;

  h3 {
    margin: 0;
    font-size: 1.7rem;
    background: #000;
    color: #fff;
    text-align: center;
    font-style: italic;
    padding: 4px;
  }
  table {
    font-family: sans-serif;
    padding: 4px 4px 0;
    width: 100%;

    td {
      font-weight: bold;
      padding-bottom: 10px;
    }
  }
  sub {
    font-weight: lighter;
    display: block;
  }
}
</style>
