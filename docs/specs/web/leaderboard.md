# Leaderboard

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | `CashflowWeb.LeaderboardLive` |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/cashflow-calculations.md`, `docs/specs/persistence/ecto-schema-and-migrations.md` |
| Truth Mode | Target |

## Target Behavior

- Ranks immutable completion snapshots by cashflow and completion date.
- Supports filters for player, timeframe, and phase where data exists.
- Links each record to `/games/{id}` recap mode.
- Handles ties predictably and visibly.

## Acceptance

- Ranking uses leaderboard snapshot rows, not mutable player rows.
- Tied values share rank.
- Empty state offers a path back to the lobby.
