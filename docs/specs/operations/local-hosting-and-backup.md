# Local Hosting And Backup

| Field | Value |
| --- | --- |
| Status | Current |
| Implementation | Complete for local v1 |
| Feature Flag | None |
| Last Verified | 2026-05-28 |
| Linear Issue | TBD |
| Depends On | `docs/specs/persistence/SPEC.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- README documents `mise`, SQLite, setup, test, server, and asset commands.
- `mise exec -- mix setup` prepares dependencies, database, seed data, and assets.
- `mise exec -- mix phx.server` starts the app for local play.
- SQLite data path is explicit and ignored by git.
- Backup export includes games, players, audit events, leaderboard records, schema version, and export timestamp.
- Backup export is reachable from the lobby/game UI and `/backup.json`.
- Backup restore validates schema version, required collections, UUIDs, datetimes, relationships, completed-game snapshots, and audit field paths before writing.
- Health/status JSON is reachable at `/healthz` and `/status.json`.
- Restore refuses to import into a non-empty database unless `--replace` is supplied.
- Demo seed data creates a realistic active game and completed game.

## Behavior

- Restore validates schema version before writing.

## Acceptance

- Backup from one SQLite database restores into a fresh SQLite database.
- Export format can be inspected without database tooling.
- Seed command refuses to run against a non-local database unless explicitly forced.
