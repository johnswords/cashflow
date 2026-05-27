# Game Domain Surface Spec

Last Verified: 2026-05-27
Status: Target specification
Truth Mode: Target, with current primitives listed as migration inventory

## Boundary

The game domain owns the Cashflow rules and state transitions. It must be usable from LiveViews, tests, seeds, import/export code, and any future API without duplicating math or business rules in UI code.

## Current Primitives

- Current stores under `src/stores/` define the useful sheet sections: income, expenses, liabilities, assets, investments, fast track, and meta.
- `src/utils/cashflow.js` and `src/backend/utils/cashflow.js` duplicate passive income, total income, total expenses, and cashflow calculations.
- `src/utils/diff.js` captures a useful field-level diff concept, but it currently allows arbitrary JSON snapshots.
- `PRD.md` names the core entities: Game, Player, AuditLogEntry, and LeaderboardRecord.

## Target Contexts And Modules

| Module | Responsibility |
| --- | --- |
| `Cashflow.Games` | Game lifecycle, player roster, phase transitions, turn saves, completion |
| `Cashflow.Sheets` | Versioned sheet schema, parsing, normalization, defaults, validation |
| `Cashflow.Calculations` | Passive income, expenses, cashflow, net worth, fast-track checks |
| `Cashflow.Audit` | Diffs, audit event validation, correction origins |
| `Cashflow.Leaderboards` | Immutable completion snapshots and ranking |

## Domain Invariants

- A game requires 2-6 players before it can become active.
- Player names and colors are unique within a game.
- A sheet has a schema version and a phase.
- Persisted money values are signed integer cents; calculation functions can use `Decimal` but never floats.
- A rat-race sheet can transition to fast track only when passive income is greater than total expenses.
- Fast-track victory can be recorded only from a fast-track player state.
- Saving a turn validates the full sheet, computes summaries, persists the new state, and records the audit event in one transaction.
- Completed games reject sheet saves, corrections, player changes, and winner changes.
- Corrections require a same-game, same-player origin audit event.
- Leaderboard ranking uses immutable completion snapshots, not live player sheet state.
- Concurrent saves must compare the draft baseline with the current persisted sheet version and return a conflict instead of overwriting silently.

## Feature Specs

- `versioned-sheet-state.md`
- `cashflow-calculations.md`
- `rat-race-fast-track-transitions.md`
- `audit-event-model.md`

## Acceptance

- Domain tests can create a full game, save rat-race turns, transition to fast track, save fast-track turns, complete the game, and verify that later mutations are rejected.
- Calculation tests prove parity for current known formulas before the old implementation is removed.
- No LiveView module performs money math except formatting a value already supplied by the domain.
