# Versioned Sheet State

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | Elixir structs, Ecto embedded schemas or validated maps, domain changesets |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/SPEC.md`, `docs/specs/persistence/ecto-schema-and-migrations.md` |
| Truth Mode | Target |

## Problem

The current backend accepts arbitrary `sheet_state`, `before_snapshot`, and `after_snapshot` payloads. That makes complete-game trust, corrections, calculations, and migrations fragile.

## Target Behavior

- Every player sheet has a `schema_version`.
- Every player sheet has a `phase`: `rat_race` or `fast_track`.
- Sheet state is validated before persistence and before audit capture.
- Unknown fields are rejected unless they are explicitly contained in a versioned extension map.
- Defaults are generated in Elixir, not copied from Vuex module initialization.
- Migration functions convert older sheet versions to the current version before gameplay mutation.

## Required Sections

- `meta`: profession, auditor, notes, optional occupation-card metadata.
- `income`: salary, interest, dividends, real estate income, business income.
- `expenses`: taxes, mortgage, loans, credit cards, retail, other, children, miscellaneous, computed bank loan payment.
- `assets`: savings, real estate, businesses, stocks, optional cash-on-hand.
- `liabilities`: mortgage, school loan, car loan, credit card, retail debt, bank loan.
- `fast_track`: dream, passive income start, cashflow day income, business purchases, dream completion state.

## Acceptance

- Invalid section names fail validation.
- Signed decimal money values round-trip without losing sign or cents where cents are allowed.
- The default sheet is deterministic and test-covered.
- Importing a legacy snapshot either converts to the current schema or returns a structured error.
