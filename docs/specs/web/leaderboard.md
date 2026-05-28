# Leaderboard

| Field | Value |
| --- | --- |
| Status | Current |
| Implementation | Complete for v1 |
| Feature Flag | None |
| Last Verified | 2026-05-28 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/cashflow-calculations.md`, `docs/specs/persistence/ecto-schema-and-migrations.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Ranks immutable completion snapshots by cashflow and completion date.
- Links each record to `/games/{id}`.
- Shows an empty state when no games are completed.
- Tied cashflow values share rank.
- Mobile view keeps all columns reachable with horizontal table scroll.
- Filters by player, timeframe, and phase where data exists.

## Acceptance

- Ranking uses leaderboard snapshot rows, not mutable player rows.
- Tied values share rank.
- Empty state offers a path back to the lobby.
