# End Game And Recap

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | `CashflowWeb.GameLive` completion modal and recap mode |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/SPEC.md`, `docs/specs/persistence/ecto-schema-and-migrations.md` |
| Truth Mode | Target |

## Target Behavior

- Host selects the winner and optional completion comment.
- Completion preview shows immutable snapshot values for the winner and summary values for every player.
- Confirming completion marks the game completed and creates leaderboard records in one transaction.
- Recap mode shows read-only final sheets, audit timeline, winner comment, and export options.

## Acceptance

- Completion rejects missing winner, invalid winner, or already completed game.
- After completion, sheet routes render read-only or redirect to recap.
- Leaderboard values do not change if historical player state is later imported or repaired.
