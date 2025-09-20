<template>
  <tr :class="title ? 'line-input' : 'blank-line-input'">
    <td>
      <label v-if="title">{{ title }}:</label>
      <input v-if="hasText" type="text" autocomplete="off" :value="text" @input="$emit('updateText', $event.target.value)" />
    </td>
    <td :colspan="hasText ? 1 : 2">
      <dollar-format-input :value="value" @input="$emit('updateValue', $event)" :readonly="readonly" />
    </td>
  </tr>
</template>

<script>
import DollarFormatInput from "./DollarFormatInput.vue";

export default {
  components: { DollarFormatInput },
  props: {
    title: String,
    text: String,
    value: Number,
    readonly: { type: Boolean, default: false },
    hasText: { type: Boolean, default: true }
  }
};
</script>

<style scoped lang="scss">
tr.line-input > td:first-child {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.45rem;
  flex-wrap: wrap;
}

tr.line-input > td:first-child > label {
  min-width: 200px;
  max-width: 320px;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: rgba(156, 246, 255, 0.88);
  line-height: 1.3;
}

tr.line-input > td:first-child > input {
  width: 100%;
}

.line-input,
.blank-line-input {
  font-family: "Press Start 2P", monospace;
  font-size: 0.58rem;
  letter-spacing: 0.04em;
  color: #f6f3ff;
}

.line-input.all-text {
  font-size: 0.58rem;
  color: rgba(244, 211, 94, 0.85);
}

tr.line-input td:last-child,
tr.blank-line-input td:last-child {
  width: 100%;
}
</style>
