# Versioned Sheet State

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/SPEC.md`, `docs/specs/persistence/ecto-schema-and-migrations.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Every player sheet has `schema_version: 1`.
- Every player sheet has a `phase`: `rat_race` or `fast_track`.
- Defaults are generated in Elixir through `Cashflow.Sheets`, `Cashflow.Sheets.RatRace`, and `Cashflow.Sheets.FastTrack`.
- Known money fields normalize to signed integer cents.
- Known Rat Race and Fast Track sheet sections are normalized before persistence.
- Unknown keys are pruned during normalization so arbitrary sheet payloads do not persist.
- `Cashflow.Sheets.valid_path?/1` exposes the current schema path allowlist for audit validation.
- The default sheet and representative normalization paths are test-covered.

## Problem

The retired backend accepted arbitrary `sheet_state`, `before_snapshot`, and `after_snapshot` payloads. That made complete-game trust, corrections, calculations, and migrations fragile.

## Target Gaps

- Migration functions convert older sheet versions to the current version before gameplay mutation.
- If future UI/import flows need operator feedback for unknown fields, normalization should return structured field-level errors instead of silent pruning.

## Required Sections

- `meta`: profession, auditor, notes, optional occupation-card metadata.
- `income`: salary, interest, dividends, real estate income, business income.
- `expenses`: taxes, mortgage, loans, credit cards, retail, other, children, miscellaneous, computed bank loan payment.
- `assets`: savings, real estate, businesses, stocks, optional cash-on-hand.
- `liabilities`: mortgage, school loan, car loan, credit card, retail debt, bank loan.
- `fast_track`: dream, passive income start, cashflow day income, business purchases, dream completion state.

## Acceptance

- Invalid section names do not persist in normalized sheet state.
- Signed decimal money values round-trip without losing sign or cents where cents are allowed.
- The default sheet is deterministic and test-covered.
- Importing a legacy snapshot either converts to the current schema or returns a structured error.
