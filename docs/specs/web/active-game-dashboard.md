# Active Game Dashboard

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/cashflow-calculations.md`, `docs/specs/game-domain/audit-event-model.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Shows all players with phase, cash, salary, passive income, total income, total expenses, and cashflow.
- Opens player sheets, audit timeline, leaderboard, Fast Track transition, and completion controls.
- Keeps dashboard summaries read-only and derived from domain summaries.
- Refreshes after successful game writes through PubSub.
- Completed games switch edit buttons to view-sheet buttons.

## Target Behavior

- Adds latest activity and stronger save-confidence indicators.
- Shows save confidence: last updated time and any failed operation state.

## Acceptance

- Dashboard updates after a sheet save without a full page reload.
- Completed games switch the same route into recap mode with no edit controls.
- Player colors are accents and never the only way to identify a player.
