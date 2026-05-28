# Persistence Surface Spec

Last Verified: 2026-05-28
Status: Partial
Truth Mode: Current implementation plus target/deferred gaps

## Boundary

The persistence surface owns Ecto schemas, migrations, database constraints, adapter compatibility, data import/export, and release-time database behavior.

## Current Database Strategy

- SQLite is the default database for local and single-host gameplay.
- Ecto contexts are the only public write boundary.
- `Ecto.Multi` is used for multi-record operations such as turn saves, corrections, phase transitions, and game completion.
- Persisted money is signed integer cents.
- Rows that participate in sheet editing include an optimistic version or equivalent timestamp check.

## Current Tables

| Table | Purpose |
| --- | --- |
| `games` | Title, lifecycle status, timestamps, completion metadata |
| `players` | Roster, color, profession, phase, current sheet state/version |
| `audit_events` | Append-only event log for turns, corrections, phase transitions, completion |
| `leaderboard_records` | Immutable completion snapshots and ranking data |

## Constraints And Guarantees

- Foreign keys are enforced.
- Game status values are constrained.
- Player colors and names are unique within a game.
- Audit event origin references are valid when present.
- Completed-game immutability is enforced in contexts and covered by tests; database constraints should reinforce it where practical.
- Money is stored using a representation that behaves consistently in SQLite and Postgres.
- Stale writes are rejected by context logic and covered by tests.
- Backup restore/import validates backup shape and relationships before writing.
- The Postgres compatibility gate script exists at `scripts/check-postgres-compat.sh`.
- The Postgres compatibility gate has been run against a local Homebrew Postgres database.

## Target And Deferred Gaps

- The Postgres compatibility script must be run against the hosted Postgres database before hosted deployment.
- `sheet_versions` and `backups` tables remain optional target tables, not current schema.
- Legacy data import is deferred unless real historical data must be preserved.

## Feature Specs

- `ecto-schema-and-migrations.md`
- `sqlite-postgres-compatibility.md`
- `legacy-data-migration.md`

## Acceptance

- `mix ecto.migrate` works against SQLite.
- A Postgres compatibility check is available before hosted deployment.
- A transaction failure during save/correction/completion leaves no partial writes.
- Backup restore refuses unsupported schema versions and non-empty imports unless `--replace` is explicit.
