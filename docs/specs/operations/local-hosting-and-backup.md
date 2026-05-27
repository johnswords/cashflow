# Local Hosting And Backup

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | Phoenix release/dev commands, Ecto tasks, backup scripts |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/persistence/SPEC.md` |
| Truth Mode | Target |

## Target Behavior

- Development setup documents Elixir, Erlang/OTP, Phoenix, SQLite, and optional Postgres prerequisites.
- A single command starts the app for local game night after setup.
- SQLite data path is explicit and not committed.
- Backup exports include games, players, audit events, leaderboard records, and schema metadata.
- Restore validates schema version before writing.
- Demo seed data can create a realistic active game and completed game for design review.

## Acceptance

- Backup from one SQLite database restores into a fresh SQLite database.
- Export format can be inspected without database tooling.
- Seed command refuses to run against a non-local database unless explicitly forced.
