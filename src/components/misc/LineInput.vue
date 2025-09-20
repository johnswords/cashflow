<template>
  <tr :class="title ? 'line-input' : 'blank-line-input'">
    <td>
      <label v-if="title">{{ title }}:</label>
      <input v-if="hasText" type="text" autocomplete="off" :value="text" @input="$emit('updateText', $event.target.value)" />
    </td>
    <td :colspan="title ? 1 : 2">
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
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
  color: rgba(244, 211, 94, 0.95);
}

tr.line-input > td:first-child > label {
  flex: 0 0 auto;
  min-width: 160px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(244, 211, 94, 0.95);
  line-height: 1.35;
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  display: block;
}

tr.line-input > td:first-child > input[type="text"] {
  flex: 1 1 200px;
  width: auto;
  background: rgba(20, 14, 52, 0.95) !important;
  color: #f4d35e !important;
  border: 1px solid rgba(244, 211, 94, 0.3) !important;
}

.line-input,
.blank-line-input {
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  letter-spacing: 0.05em;
  color: rgba(244, 211, 94, 0.95);
}

.line-input.all-text {
  font-size: 0.6rem;
  color: rgba(244, 211, 94, 0.9);
}

tr.line-input td:last-child,
tr.blank-line-input td:last-child {
  width: 100%;
}
</style>
