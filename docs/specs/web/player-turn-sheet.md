# Player Turn Sheet

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | `CashflowWeb.PlayerSheetLive` plus sheet LiveComponents |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/versioned-sheet-state.md`, `docs/specs/game-domain/cashflow-calculations.md` |
| Truth Mode | Target |

## Target Behavior

- Provides a dense but legible sheet for Rat Race and Fast Track.
- Uses section-level LiveComponents for income, expenses, liabilities, assets, investments, and fast-track state when they reduce parent LiveView complexity.
- Maintains an explicit draft state until the host saves or discards.
- Shows dirty state and a diff review before committing.
- Saves call a domain transaction that updates the sheet and writes audit.
- Supports keyboard and touch operation for all row actions.

## Acceptance

- Mobile view has meaningful sheet content visible without a tiny trapped scroll region.
- Cancel discards the draft and leaves canonical state unchanged.
- Save with validation errors keeps the draft visible and identifies the fields to fix.
- Save with changes returns to the dashboard or stays in sheet mode according to the explicit host action.
