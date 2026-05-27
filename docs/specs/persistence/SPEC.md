# Persistence Surface Spec

Last Verified: 2026-05-27
Status: Target specification
Truth Mode: Target

## Boundary

The persistence surface owns Ecto schemas, migrations, database constraints, adapter compatibility, data import/export, and release-time database behavior.

## Target Database Strategy

- SQLite is the default database for local and single-host gameplay.
- Postgres compatibility is required at the migration and schema-design level.
- Ecto contexts are the only public write boundary.
- `Ecto.Multi` is used for multi-record operations such as turn saves, corrections, phase transitions, and game completion.
- Migrations must avoid adapter-specific features unless the compatibility spec explicitly documents both SQLite and Postgres paths.
- Persisted money is signed integer cents. Percentages and ratios use Decimal-compatible text or numeric fields with adapter behavior documented.
- Rows that participate in sheet editing include an optimistic version or equivalent timestamp check.

## Target Tables

| Table | Purpose |
| --- | --- |
| `games` | Title, lifecycle status, timestamps, completion metadata |
| `players` | Roster, color, profession, phase, current sheet state/version |
| `sheet_versions` | Optional append-only snapshots if event replay/rollback requires them |
| `audit_events` | Append-only event log for turns, corrections, phase transitions, completion |
| `leaderboard_records` | Immutable completion snapshots and ranking data |
| `backups` | Optional local backup manifest metadata |

## Constraints And Guarantees

- Foreign keys are enforced.
- Game status values are constrained.
- Player colors and names are unique within a game.
- Audit event origin references are valid when present.
- Completed-game immutability is enforced in contexts and covered by tests; database constraints should reinforce it where practical.
- Money is stored using a representation that behaves consistently in SQLite and Postgres.
- Stale writes are rejected by context logic and covered by tests.

## Feature Specs

- `ecto-schema-and-migrations.md`
- `sqlite-postgres-compatibility.md`
- `legacy-data-migration.md`

## Acceptance

- `mix ecto.migrate` works against SQLite.
- A Postgres compatibility check is available before hosted deployment.
- A transaction failure during save/correction/completion leaves no partial writes.
