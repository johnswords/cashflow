# End Game And Recap

| Field | Value |
| --- | --- |
| Status | Current |
| Implementation | Complete for v1 |
| Feature Flag | None |
| Last Verified | 2026-05-28 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/SPEC.md`, `docs/specs/persistence/ecto-schema-and-migrations.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Host selects the winner and optional completion comment.
- Confirming completion marks the game completed and creates leaderboard records in one transaction.
- Completed games render the dashboard route without edit controls and player sheets in read-only mode.
- Completion preview shows snapshot values for every player and highlights the selected winner.
- Completed recap shows immutable leaderboard snapshots, audit navigation, winner comment, and backup export.
- Completion rejects invalid or already completed games through the domain context.

## Acceptance

- Completion rejects missing winner, invalid winner, or already completed game.
- After completion, sheet routes render read-only or redirect to recap.
- Leaderboard values do not change if historical player state is later imported or repaired.
