# Ecto Schema And Migrations

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | Ecto schemas, migrations, changesets, `Ecto.Multi` |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/versioned-sheet-state.md`, `docs/specs/game-domain/audit-event-model.md` |
| Truth Mode | Target |

## Target Behavior

- Migrations create all core tables with explicit primary keys, foreign keys, timestamps, and indexes.
- Schemas expose changesets for all externally supplied fields.
- Domain contexts own insert/update/delete operations.
- Turn saves, corrections, phase transitions, and completion are transactional.
- Seed data uses public context functions, not raw database writes.

## Schema Notes

- Prefer UUID/binary IDs where both adapters can support readable local debugging.
- Store persisted money as signed integer cents. Do not store financial truth as floats, Decimal strings, or adapter-specific decimal columns.
- Store percentages and ratios separately using a documented Decimal-compatible representation.
- Store versioned sheet maps only after validation.
- Store leaderboard snapshots as denormalized columns sufficient for ranking and recap.
- Add `lock_version` or an equivalent optimistic concurrency field to mutable game/player sheet records.

## Acceptance

- Migration tests verify required tables and indexes exist.
- Changeset tests cover invalid status, duplicate colors, duplicate names, invalid event type, and invalid sheet version.
- Transaction tests prove partial writes roll back.
- Stale update tests prove older sheet drafts cannot overwrite newer records.
