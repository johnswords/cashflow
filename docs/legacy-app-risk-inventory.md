# Legacy App Risk Inventory

Last Verified: 2026-05-27
Status: Current-state evidence for the Phoenix rewrite
Truth Mode: Current tracked repository sources

## Purpose

This file keeps the rewrite risk inventory in tracked documentation. It replaces earlier references to `.context/` audit notes, which are local workspace artifacts and are not available from a fresh checkout.

Use this as evidence for why `docs/SPEC.md` treats the current Vue/Koa app as legacy implementation inventory rather than the target architecture.

## Tracked Risk Summary

### Runtime And Dependency Drift

- `package.json` uses Vue 2, Vue CLI 4, Koa, Kysely, and better-sqlite3.
- `.gitignore` ignores `package-lock.json`, so fresh installs are not locked by the repository.
- `package.json` has no automated test script.
- `README.md` documents manual regression testing as the current validation path.

Rewrite implication: the target Phoenix app needs committed dependency locking, automated tests, and one-command validation before it replaces the current app.

### Completed-Game Mutability

- `PRD.md` states that games are immutable once completed.
- The current backend exposes player sheet update and audit append behavior in `src/backend/routes/games.js`.
- The current UI still uses game resume/open-sheet flows for game access under `src/components/app/`.

Rewrite implication: completed-game immutability must be enforced in domain contexts and covered by tests, not left to UI convention.

### Untyped Sheet And Audit Payloads

- `src/backend/validators/games.js` accepts `sheetState` with `z.unknown()`.
- `src/backend/validators/common.js` accepts audit snapshots with `z.unknown()`.
- `src/backend/db/migrations/0001_init.js` stores sheet and audit snapshots as text payloads without a schema version.

Rewrite implication: player sheets and audit snapshots must be versioned and validated before persistence.

### Duplicated Financial Calculations

- `src/utils/cashflow.js` and `src/backend/utils/cashflow.js` both implement cashflow calculations.
- The two implementations are similar but not identical, including bank-loan expense behavior.

Rewrite implication: all money parsing, normalization, and calculations must live in one Elixir domain layer.

### Money Input Safety

- The legacy UI includes custom money inputs under `src/components/misc/`.
- Current target specs require signed integer cents for persisted money and Decimal-backed calculations where needed.

Rewrite implication: money input parsing must be tested at the domain boundary and must preserve signs and cents where allowed.

### Correction And Audit Semantics

- The current app has useful audit and correction concepts, but the correction flow is driven through frontend state and arbitrary snapshots.
- `src/utils/diff.js` provides a reusable field-diff concept, but it is not schema-aware.

Rewrite implication: corrections must be draft-based until confirmed, audit origins must be validated, and field paths must be checked against the versioned sheet schema.

### Dense Sheet Usability

- `src/components/app/PlayerSheetView.vue` owns the current full-sheet layout.
- Touch/phone usability and persistent row controls are not guaranteed by the legacy component structure.

Rewrite implication: the LiveView sheet must be designed and tested across desktop, tablet, and phone viewports before it replaces the current app.

### Legacy Data Migration

- Current persistence uses the Koa/Kysely SQLite schema in `src/backend/db/migrations/0001_init.js`.
- Real game data, if any, lives outside the tracked repo under a local SQLite data path.

Rewrite implication: legacy import is optional unless real historical game data must be preserved, but any import must read from a copied database and convert through validated target schemas.
