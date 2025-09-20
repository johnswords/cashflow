<template>
  <transition name="modal-fade">
    <div ref="win" class="modal-backdrop" tabindex="0" @keyup.esc="close" @keyup.ctrl.c="close" @click="close">
      <div class="modal" role="dialog" aria-labelledby="modalTitle" aria-describedby="modalDescription" @click="dontClose">
        <header class="modal-header" id="modalTitle">
          <slot name="header" />
          <button type="button" class="close-x" @click="close" aria-label="Close modal">
            <img src="@/images/close.svg" width="24" height="24" />
          </button>
        </header>
        <section class="modal-body" id="modalDescription">
          <slot name="body" />
        </section>
        <footer class="modal-footer">
          <button type="button" class="modal-delete" @click="del" aria-label="Close modal">
            <img src="@/images/close.svg" width="12" height="12" />
            Delete
          </button>
          <slot name="footer" />
          <button type="button" class="modal-close" @click="close" aria-label="Close modal">
            <img src="@/images/check.svg" width="12" height="12" />
            Done
          </button>
        </footer>
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  methods: {
    close() {
      this.$emit("close");
    },
    dontClose(event) {
      event.stopPropagation();
    },
    del() {
      this.$emit("del");
    }
  },
  mounted() {
    this.$refs.win.focus();
  }
};
</script>

<style lang="scss">
.modal-fade-enter,
.modal-fade-leave-active {
  opacity: 0;
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease;
}

.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(3, 0, 14, 0.8);
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 1.5rem;

  .modal {
    width: min(540px, 100%);
    background: linear-gradient(160deg, rgba(16, 12, 40, 0.96), rgba(4, 1, 18, 0.96));
    border: 1px solid rgba(156, 39, 176, 0.45);
    border-radius: 18px;
    box-shadow: 0 24px 60px rgba(0, 0, 0, 0.45);
    overflow: hidden;
    display: flex;
    flex-direction: column;
    color: #fdf9ff;

    .modal-header,
    .modal-footer {
      padding: 1.25rem 1.5rem;
      display: flex;
      align-items: center;
      font-family: "Press Start 2P", monospace;
    }

    .modal-header {
      justify-content: space-between;
      background: rgba(156, 39, 176, 0.2);
      border-bottom: 1px solid rgba(244, 211, 94, 0.25);
      font-size: 0.95rem;
      letter-spacing: 0.1em;
      text-transform: uppercase;

      .close-x {
        border: 0;
        padding: 0;
        background: transparent;
        display: grid;
        place-items: center;
        width: 2.5rem;
        height: 2.5rem;
      }
    }

    .modal-body {
      padding: 1.5rem;
      display: flex;
      flex-direction: column;
      gap: 1rem;

      table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0 0.9rem;
      }

      table tr {
        background: rgba(20, 14, 52, 0.92);
        border: 1px solid rgba(244, 211, 94, 0.18);
        border-radius: 14px;
      }

      table tr td {
        padding: 0.85rem 1rem;
        font-family: "Press Start 2P", monospace;
        font-size: 0.6rem;
        letter-spacing: 0.06em;
        color: rgba(244, 211, 94, 0.85);

        label {
          display: block;
          text-transform: uppercase;
          color: rgba(156, 246, 255, 0.85);
        }

        input {
          width: 100%;
        }
      }
    }

    .modal-footer {
      gap: 1rem;
      justify-content: flex-end;
      border-top: 1px solid rgba(244, 211, 94, 0.25);

      button {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.65rem;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        padding: 0.65rem 1.35rem;
        border-radius: 12px;
        border: 2px solid rgba(244, 211, 94, 0.5);
        background: rgba(10, 10, 30, 0.9);
        color: rgba(244, 211, 94, 0.92);
        cursor: pointer;
        transition: transform 0.15s ease, box-shadow 0.15s ease;

        &:hover {
          transform: translateY(-1px);
          box-shadow: 0 10px 24px rgba(244, 211, 94, 0.25);
        }

        img {
          filter: invert(1);
        }

        &.modal-delete {
          border-color: rgba(255, 118, 137, 0.7);
          color: #ff8a80;
        }
      }
    }
  }
}

@media (max-width: 720px) {
  .modal-backdrop {
    padding: 1rem;

    .modal {
      width: 100%;

      .modal-body {
        padding: 1.25rem;
      }
    }
  }
}
</style>
