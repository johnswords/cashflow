<template>
  <div class="fast-track-page">
    <section class="fast-track-page__section">
      <div class="fast-track-page__grid">
        <div class="fast-track-page__panel fast-track-page__panel--wide">
          <fast-track-congratulations />
        </div>
        <div class="fast-track-page__panel">
          <your-buyout />
        </div>
        <div class="fast-track-page__panel fast-track-page__panel--wide">
          <how-to-win />
        </div>
        <div class="fast-track-page__panel">
          <explanation-of-100x />
        </div>
      </div>
    </section>
    <section class="fast-track-page__section">
      <div class="fast-track-page__panel fast-track-page__panel--records">
        <income-record-area />
      </div>
    </section>
  </div>
</template>

<script>
import FastTrackCongratulations from "./gamesetup/FastTrackCongratulations.vue";
import YourBuyout from "./gamesetup/YourBuyout.vue";
import HowToWin from "./gamesetup/HowToWin.vue";
import ExplanationOf100x from "./gamesetup/ExplanationOf100x.vue";
import IncomeRecordArea from "./incomerecord/IncomeRecordArea.vue";

export default {
  components: {
    FastTrackCongratulations,
    YourBuyout,
    HowToWin,
    ExplanationOf100x,
    IncomeRecordArea
  }
};
</script>

<style scoped lang="scss">
.fast-track-page {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.fast-track-page__section {
  background: linear-gradient(145deg, rgba(10, 6, 34, 0.92), rgba(4, 1, 14, 0.92));
  border: 1px solid rgba(156, 39, 176, 0.35);
  border-radius: 22px;
  box-shadow: 0 18px 40px rgba(0, 0, 0, 0.35);
  padding: 2rem 2.25rem;
  overflow: hidden;
}

.fast-track-page__grid {
  display: grid;
  gap: 1.75rem;
  grid-template-columns: minmax(0, 1fr);
}


.fast-track-page__panel {
  background: transparent;
  border: 0;
  padding: 0;
  color: #f6f3ff;
  font-family: "Press Start 2P", monospace;
}

.fast-track-page__panel--records {
  padding: 0;
}

.fast-track-page__panel ::v-deep h1,
.fast-track-page__panel ::v-deep h2,
.fast-track-page__panel ::v-deep h3,
.fast-track-page__panel ::v-deep h4,
.fast-track-page__panel ::v-deep h5 {
  font-family: "Press Start 2P", monospace;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.92);
}

.fast-track-page__panel ::v-deep h1 {
  font-size: 1.6rem;
  text-align: center;
}

.fast-track-page__panel ::v-deep h2 {
  font-size: 1rem;
  text-align: center;
  color: rgba(156, 246, 255, 0.85);
}

.fast-track-page__panel ::v-deep label,
.fast-track-page__panel ::v-deep th {
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.fast-track-page__panel ::v-deep table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 0.75rem;
}

.fast-track-page__panel ::v-deep td,
.fast-track-page__panel ::v-deep th {
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  color: rgba(244, 211, 94, 0.85);
}

.fast-track-page__panel ::v-deep input,
.fast-track-page__panel ::v-deep select {
  width: 100%;
}

@media (min-width: 1100px) {
  .fast-track-page__grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .fast-track-page__panel--wide {
    grid-column: span 2;
  }
}

@media (max-width: 768px) {
  .fast-track-page__section {
    padding: 1.75rem 1.25rem;
    border-radius: 18px;
  }

  .fast-track-page__panel {
    padding: 0;
  }
}
</style>
