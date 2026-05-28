# Game Domain Surface Spec

Last Verified: 2026-05-27
Status: Partial
Truth Mode: Current implementation plus retained target invariants

## Boundary

The game domain owns the Cashflow rules and state transitions. It must be usable from LiveViews, tests, seeds, import/export code, and any future API without duplicating math or business rules in UI code.

## Retired Prototype Primitives

- Retired stores under `src/stores/` defined the useful sheet sections: income, expenses, liabilities, assets, investments, fast track, and meta.
- Retired `src/utils/cashflow.js` and `src/backend/utils/cashflow.js` duplicated passive income, total income, total expenses, and cashflow calculations.
- Retired `src/utils/diff.js` captured a useful field-level diff concept, but allowed arbitrary JSON snapshots.
- `PRD.md` names the core entities: Game, Player, AuditLogEntry, and LeaderboardRecord.

## Current Contexts And Modules

| Module | Responsibility |
| --- | --- |
| `Cashflow.Games` | Game lifecycle, player roster, phase transitions, turn saves, completion |
| `Cashflow.Sheets` | Versioned sheet schema, parsing, normalization, defaults, validation |
| `Cashflow.Calculations` | Passive income, expenses, cashflow, net worth, fast-track checks |
| `Cashflow.Games.AuditEvent` | Audit event schema, event-type validation, correction origin references |
| `Cashflow.Games.LeaderboardRecord` | Immutable completion snapshots and ranking data |

## Current Domain Invariants

- A game requires 2-6 players before it can become active.
- Player names and colors are unique within a game.
- A sheet has a schema version and a phase.
- Sheet normalization prunes unknown keys and validates audit field paths against the versioned schema.
- Persisted money values are signed integer cents; calculation functions can use `Decimal` but never floats.
- A rat-race sheet can transition to fast track only when passive income is greater than total expenses.
- Saving a turn validates the full sheet, computes summaries, persists the new state, and records the audit event in one transaction.
- Completed games reject sheet saves, corrections, player changes, and winner changes.
- Corrections require a same-game, same-player origin audit event.
- Leaderboard ranking uses immutable completion snapshots, not live player sheet state.
- Concurrent saves must compare the draft baseline with the current persisted sheet version and return a conflict instead of overwriting silently.

## Target Gaps

- A separate `setup` game lifecycle state is still target-state only; created games currently enter `active`.
- Fast-track victory is not yet enforced as the only completion path.
- Future sheet-schema migration functions are still needed before accepting older sheet versions.
- If future UI/import flows need operator feedback for unknown fields, normalization should return structured errors instead of silent pruning.
- Legacy snapshot import/migration remains deferred unless real data appears.

## Feature Specs

- `versioned-sheet-state.md`
- `cashflow-calculations.md`
- `rat-race-fast-track-transitions.md`
- `audit-event-model.md`

## Acceptance

- Domain tests can create a full game, save rat-race turns, transition to fast track, save fast-track turns, complete the game, and verify that later mutations are rejected.
- Calculation tests prove parity for known legacy formulas retained in the spec inventory.
- No LiveView module performs money math except formatting a value already supplied by the domain.
