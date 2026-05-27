# Active Game Dashboard

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | `CashflowWeb.GameLive` |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/cashflow-calculations.md`, `docs/specs/game-domain/audit-event-model.md` |
| Truth Mode | Target |

## Target Behavior

- Shows all players with phase, cash, salary, passive income, total income, total expenses, cashflow, and latest activity.
- Makes the next action obvious: open sheet, view audit, transition to fast track where eligible, or complete game.
- Shows save confidence: last updated time and any failed operation state.
- Keeps dashboard summaries read-only and derived from domain summaries.

## Acceptance

- Dashboard updates after a sheet save without a full page reload.
- Completed games switch the same route into recap mode with no edit controls.
- Player colors are accents and never the only way to identify a player.
