# Legacy App Risk Inventory

Last Verified: 2026-05-27
Status: Historical evidence retained after legacy retirement
Truth Mode: Archived tracked sources from git history

## Purpose

This file keeps the rewrite risk inventory in tracked documentation. It replaces earlier references to `.context/` audit notes, which are local workspace artifacts and are not available from a fresh checkout.

Use this as historical evidence for why the Vue/Koa runtime was retired. The referenced files were removed from active tracked source after Phoenix parity; inspect git history before the retirement commit if exact legacy source is needed.

## Tracked Risk Summary

### Runtime And Dependency Drift

- The retired `package.json` used Vue 2, Vue CLI 4, Koa, Kysely, and better-sqlite3.
- The retired `.gitignore` ignored `package-lock.json`, so fresh installs were not locked by the repository.
- The retired `package.json` had no automated test script.
- The retired `README.md` documented manual regression testing as the validation path.

Rewrite implication: the Phoenix app needs committed dependency locking, automated tests, and one-command validation.

### Completed-Game Mutability

- `PRD.md` states that games are immutable once completed.
- The retired backend exposed player sheet update and audit append behavior in `src/backend/routes/games.js`.
- The retired UI used game resume/open-sheet flows for game access under `src/components/app/`.

Rewrite implication: completed-game immutability must be enforced in domain contexts and covered by tests, not left to UI convention.

### Untyped Sheet And Audit Payloads

- The retired `src/backend/validators/games.js` accepted `sheetState` with `z.unknown()`.
- The retired `src/backend/validators/common.js` accepted audit snapshots with `z.unknown()`.
- The retired `src/backend/db/migrations/0001_init.js` stored sheet and audit snapshots as text payloads without a schema version.

Rewrite implication: player sheets and audit snapshots must be versioned and validated before persistence.

### Duplicated Financial Calculations

- The retired `src/utils/cashflow.js` and `src/backend/utils/cashflow.js` both implemented cashflow calculations.
- The two implementations are similar but not identical, including bank-loan expense behavior.

Rewrite implication: all money parsing, normalization, and calculations must live in one Elixir domain layer.

### Money Input Safety

- The retired legacy UI included custom money inputs under `src/components/misc/`.
- Current target specs require signed integer cents for persisted money and Decimal-backed calculations where needed.

Rewrite implication: money input parsing must be tested at the domain boundary and must preserve signs and cents where allowed.

### Correction And Audit Semantics

- The current app has useful audit and correction concepts, but the correction flow is driven through frontend state and arbitrary snapshots.
- The retired `src/utils/diff.js` provided a reusable field-diff concept, but it was not schema-aware.

Rewrite implication: corrections must be draft-based until confirmed, audit origins must be validated, and field paths must be checked against the versioned sheet schema.

### Dense Sheet Usability

- The retired `src/components/app/PlayerSheetView.vue` owned the full-sheet layout.
- Touch/phone usability and persistent row controls are not guaranteed by the legacy component structure.

Rewrite implication: the LiveView sheet must be designed and tested across desktop, tablet, and phone viewports before it replaces the current app.

### Legacy Data Migration

- Retired persistence used the Koa/Kysely SQLite schema in `src/backend/db/migrations/0001_init.js`.
- Real game data, if any, lives outside the tracked repo under a local SQLite data path.

Rewrite implication: legacy import is optional unless real historical game data must be preserved, but any import must read from a copied database and convert through validated target schemas.
