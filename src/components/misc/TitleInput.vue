<template>
  <div class="title-input">
    <label class="title-input__label">
      <slot />
    </label>
    <input
      type="text"
      autocomplete="off"
      :value="value"
      @input="$emit('input', $event.target.value)"
      :tabindex="tabindex"
      class="title-input__field"
    />
  </div>
</template>

<script>
export default {
  props: {
    value: String,
    tabindex: { type: Number, default: 0 }
  }
};
</script>

<style lang="scss" scoped>
.title-input {
  display: flex;
  align-items: center;
  gap: 0.9rem;
  width: 100%;
}

.title-input__label {
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: rgba(156, 246, 255, 0.85);
}

.title-input__field {
  flex: 1;
  font-size: 1.2rem;
  font-family: "Press Start 2P", monospace;
  letter-spacing: 0.04em;
  padding: 0.75rem 1rem;
  border-radius: 14px;
  border: 1px solid rgba(244, 211, 94, 0.3);
  background: rgba(16, 12, 40, 0.9);
  color: #fdf9ff;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.title-input__field:focus {
  outline: none;
  border-color: rgba(244, 211, 94, 0.7);
  box-shadow: 0 0 0 2px rgba(244, 211, 94, 0.25);
}
</style>
