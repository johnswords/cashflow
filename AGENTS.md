# AGENTS.md

Read `README.md`, `docs/SPEC.md`, and the relevant `docs/specs/**` surface specs before implementation work.

## Active App

The active runtime is an Elixir/Phoenix LiveView app at the repository root.

- Use `mise exec -- ...` for Elixir/Phoenix commands.
- Keep money persisted as signed integer cents.
- Keep game rules, calculations, sheet validation, audit semantics, and status transitions in `lib/cashflow/**`, not in LiveViews.
- Keep LiveViews focused on forms, navigation, and presentation.
- Use plain HEEx/function components/LiveComponents. Svelte or large custom JavaScript needs a documented exception.
- SQLite is the default local database. Do not assume Postgres compatibility without running the documented compatibility gate.

## Commands

```bash
mise exec -- mix setup
mise exec -- mix phx.server
mise exec -- mix test
mise exec -- mix format --check-formatted
bash scripts/check-specs.sh
```

## Legacy Reference

The Vue/Koa app under `src/` is legacy reference material. Do not add new product work there unless the user explicitly asks for legacy behavior. Useful legacy facts and risks are tracked in `docs/legacy-app-risk-inventory.md`.

## Validation Expectations

Every significant change should have a direct proof:

- Domain/persistence changes: ExUnit tests.
- LiveView changes: LiveView tests plus browser verification when UI behavior changes.
- Spec hierarchy changes: `bash scripts/check-specs.sh`.
