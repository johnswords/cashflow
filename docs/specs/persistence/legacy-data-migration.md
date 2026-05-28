# Legacy Data Migration

| Field | Value |
| --- | --- |
| Status | Deferred |
| Implementation | Deferred |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `ecto-schema-and-migrations.md`, `docs/specs/game-domain/versioned-sheet-state.md` |
| Truth Mode | Deferred target |

## Target Behavior

- Legacy Vue/Koa SQLite import is optional for rewrite v1 unless existing real game data must be preserved.
- If implemented, import reads the legacy tables and converts games, players, audit events, and leaderboard rows through public context functions or dedicated import contexts.
- Legacy sheet JSON is converted into the current versioned sheet schema.
- Records that cannot be converted are reported with structured errors and are not partially imported.
- Import does not mutate the source SQLite database.
- The tracked Vue/Koa runtime has been removed; any future import must run against an explicitly supplied copy of a legacy SQLite database.

## Acceptance

- Import can run against a copied legacy SQLite database.
- A successful import produces playable active games and read-only completed recaps.
- Invalid legacy sheet blobs produce a report rather than crashing or inserting unchecked state.
- The import path is removable after migration is complete.
