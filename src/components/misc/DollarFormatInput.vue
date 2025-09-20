<template>
  <input
    type="text"
    autocomplete="off"
    class="numeric"
    :readonly="readonly"
    @input="setNewValue($event.target.value)"
    :value="displayValue"
    @focus="focus"
    @blur="blur"
    ref="thisInput"
  />
</template>

<script>
export default {
  props: {
    value: Number,
    readonly: { type: Boolean, default: false }
  },
  data() {
    return {
      isFocused: false
    };
  },
  computed: {
    displayFormattedValue() {
      if (this.value) {
        return `$ ${new Intl.NumberFormat("en-US").format(this.value)}`;
      } else {
        return "";
      }
    },
    displayValue() {
      return this.isFocused ? this.value.toString() : this.displayFormattedValue;
    }
  },
  methods: {
    focus() {
      // Avoid annoying re-selecting of the text value
      if (!this.isFocused && !this.readonly) {
        this.isFocused = true;

        // select all content for easy-overwriting
        const el = this.$refs.thisInput;
        // using nextTick to wait for the editing value to drop in
        this.$nextTick(() => el.select());
      }
    },
    blur(e) {
      this.$emit("blur", e);
      this.isFocused = false;
    },
    setNewValue(val) {
      // only change the value if the user is intentionally changing it
      // (otherwise it may be emitting the displayFormattedValue as the new value)
      const valJustNumbers = parseInt(val.replace(/[^\d]/g, ""));

      // also only if the value is really a number
      if (this.isFocused) {
        if (valJustNumbers) {
          this.$emit("input", valJustNumbers);
        } else {
          this.$emit("input", 0);
        }
      }
    }
  }
};
</script>

<style scoped lang="scss">
input.numeric {
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  background: rgba(20, 14, 52, 0.95);
  color: #f4d35e;
  border: 1px solid rgba(244, 211, 94, 0.3);
  border-radius: 8px;
  padding: 0.6rem 0.8rem;
  outline: none;
  transition: all 0.3s ease;
  letter-spacing: 0.05em;
  width: 100%;
  box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.3);
}

input.numeric:focus {
  border-color: rgba(244, 211, 94, 0.8);
  background: rgba(28, 20, 68, 0.95);
  box-shadow: 0 0 12px rgba(244, 211, 94, 0.3), inset 0 2px 4px rgba(0, 0, 0, 0.3);
}

input.numeric[readonly],
input.numeric[readonly]:focus {
  background: rgba(12, 8, 34, 0.7);
  border-color: rgba(244, 211, 94, 0.15);
  color: rgba(244, 211, 94, 0.6);
  cursor: not-allowed;
}
</style>
