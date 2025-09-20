<template>
  <section class="congrats">
    <header class="congrats__header">
      <h1>Congratulations!</h1>
      <h2>You are out of the Rat Race!</h2>
    </header>
    <div class="congrats__body">
      <div class="congrats__panel">
        <h3>New Goals</h3>
        <ol>
          <li>Buy your "Dream" by landing on the Fast Track space you selected at the start of the game and purchasing it.</li>
          <li>Increase your Monthly Cash Flow by buying businesses.</li>
        </ol>
      </div>
      <div class="congrats__panel">
        <h3>You Win If</h3>
        <ol>
          <li>You are the first person to buy your Dream.</li>
          <li class="congrats__divider">&mdash; OR &mdash;</li>
          <li>You are the first person to accumulate $50,000 in Monthly Cash Flow from businesses purchased on the Fast Track.</li>
        </ol>
      </div>
    </div>
  </section>
</template>

<script>
export default {};
</script>

<style scoped lang="scss">
.congrats {
  display: flex;
  flex-direction: column;
  gap: 1.75rem;
}

.congrats__header {
  text-align: center;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}

.congrats__header h1 {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 1.6rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.95);
}

.congrats__header h2 {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 0.9rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(156, 246, 255, 0.85);
}

.congrats__body {
  display: grid;
  gap: 1.5rem;
}

.congrats__panel {
  background: linear-gradient(135deg, rgba(12, 8, 34, 0.85), rgba(20, 14, 46, 0.9));
  border: 1px solid rgba(244, 211, 94, 0.22);
  border-radius: 16px;
  padding: 1.5rem;
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.22);
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.congrats__panel h3 {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.9);
}

.congrats__panel ol {
  margin: 0;
  padding-left: 1.2rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  letter-spacing: 0.04em;
  color: rgba(253, 249, 255, 0.9);
}

.congrats__divider {
  list-style: none;
  text-align: center;
  color: rgba(244, 211, 94, 0.8);
}

@media (min-width: 900px) {
  .congrats__body {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
