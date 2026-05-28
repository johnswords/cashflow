# Player Turn Sheet

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/versioned-sheet-state.md`, `docs/specs/game-domain/cashflow-calculations.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Provides Rat Race and Fast Track sheets with section LiveComponents.
- Maintains explicit draft state until review/save or cancel.
- Shows dirty state through a diff review before committing.
- Saves call a domain transaction that updates the sheet and writes audit.
- Supports dense real estate, business, stock, Fast Track investment, dream, and notes editing.
- Completed games render player sheets in read-only mode.
- Edits after review invalidate the reviewed save action until the current draft is reviewed again.
- Invalid money and number fields show field-level errors instead of silently saving a different value.
- Core form controls meet the 44px touch-target floor for mobile play.

## Behavior

- Provides a dense but legible sheet for Rat Race and Fast Track.
- Uses section-level LiveComponents for income, expenses, liabilities, assets, investments, and fast-track state when they reduce parent LiveView complexity.
- Maintains an explicit draft state until the host saves or discards.
- Shows dirty state and a diff review before committing.
- Saves call a domain transaction that updates the sheet and writes audit.
- Supports keyboard and touch operation for all row actions.

## Target Gaps

- Further sheet-density polish can reduce scrolling on phones, but current mobile/tablet/desktop screenshots show usable controls without viewport traps.

## Acceptance

- Mobile view has meaningful sheet content visible without a tiny trapped scroll region.
- Cancel discards the draft and leaves canonical state unchanged.
- Save with validation errors keeps the draft visible and identifies the fields to fix.
- Save with changes returns to the dashboard or stays in sheet mode according to the explicit host action.
