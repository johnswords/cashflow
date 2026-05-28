# CLAUDE.md

This repository is now centered on the Phoenix LiveView rewrite.

Read `README.md`, `docs/SPEC.md`, and the relevant `docs/specs/**` files before planning or editing. The retired Vue/Koa runtime is no longer tracked source; use `docs/legacy-app-risk-inventory.md` and git history only for historical comparison.

## Runtime

Use `mise`:

```bash
mise exec -- mix setup
mise exec -- mix phx.server
mise exec -- mix test
mise exec -- mix format --check-formatted
```

## Architecture Guardrails

- `lib/cashflow/**` owns domain rules, Ecto persistence, audit semantics, calculations, and backups.
- `lib/cashflow_web/**` owns LiveView UI only.
- Persist money as signed integer cents.
- Use versioned sheet state.
- Use Ecto transactions for saves, corrections, phase transitions, and completion.
- Completed games are read-only.
- Stale sheet drafts must fail safely instead of overwriting newer state.
- Use plain HEEx/function components/LiveComponents by default.
