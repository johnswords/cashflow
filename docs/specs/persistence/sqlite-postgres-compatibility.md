# SQLite And Postgres Compatibility

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | Adapter-aware Ecto config and migration discipline |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `ecto-schema-and-migrations.md` |
| Truth Mode | Target |

## Target Behavior

- SQLite is the default for local play: file-backed, WAL mode where available, foreign keys enabled.
- Postgres can run the same logical schema for hosted deployments.
- Tests document adapter differences rather than discovering them during release.
- JSON/map usage is intentionally limited and versioned.
- Check constraints are written in a way that is either adapter-neutral or documented with equivalent adapter-specific migrations.
- Integer cents are the cross-adapter money representation. Floats are not used for persisted money.

## Known Adapter Considerations

- SQLite has different constraint and type behavior from Postgres.
- SQLite-backed sandbox tests may need to run synchronously.
- SQLite is acceptable for the v1 single-host concurrency model, but hosted multi-user play requires a Postgres compatibility gate.
- Postgres should be used for any future multi-user hosted mode or high-concurrency expectation.

## Acceptance

- Local test suite passes on SQLite.
- A documented Postgres check can run migrations and domain tests before any hosted launch.
- Backup/export format is independent of the physical adapter.
