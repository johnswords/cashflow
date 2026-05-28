# SQLite And Postgres Compatibility

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `ecto-schema-and-migrations.md` |
| Truth Mode | Current SQLite behavior plus target Postgres gate |

## Current Behavior

- SQLite is the default for local play and test execution.
- The schema uses integer cents for persisted money.
- JSON/map usage is limited to versioned sheet state, summary, audit field paths, and audit snapshots.
- Backup/export format is independent of the physical adapter.
- `scripts/check-postgres-compat.sh` creates the equivalent logical Postgres schema in a temporary schema, inserts representative rows, and rolls back.
- The gate fails unless `DATABASE_URL` is provided, except when `CASHFLOW_SKIP_POSTGRES_COMPAT=1` explicitly skips it.

## Target Behavior

- The compatibility gate must pass against the actual hosted Postgres database before hosted deployment.
- Tests document adapter differences rather than discovering them during release.
- Check constraints are written in a way that is either adapter-neutral or documented with equivalent adapter-specific migrations.
- A documented Postgres check can run migrations and domain tests before any hosted launch.

## Known Adapter Considerations

- SQLite has different constraint and type behavior from Postgres.
- SQLite-backed sandbox tests may need to run synchronously.
- SQLite is acceptable for the v1 single-host concurrency model, but hosted multi-user play requires a Postgres compatibility gate.
- Postgres should be used for any future multi-user hosted mode or high-concurrency expectation.

## Acceptance

- Local test suite passes on SQLite.
- A documented Postgres check can run migrations and domain tests before any hosted launch.
- Backup/export format is independent of the physical adapter.
