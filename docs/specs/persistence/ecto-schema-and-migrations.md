# Ecto Schema And Migrations

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/versioned-sheet-state.md`, `docs/specs/game-domain/audit-event-model.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Migrations create `games`, `players`, `audit_events`, and `leaderboard_records` with binary IDs, timestamps, foreign keys, and indexes.
- Schemas expose changesets for externally supplied fields.
- Domain contexts own game, player, audit, leaderboard, and export writes.
- Turn saves, corrections, phase transitions, and completion are transactional.
- Seed data uses public context functions.
- Mutable game/player sheet records use optimistic locking.
- Backup restore imports validated rows inside a transaction and preserves completed-game immutability.

## Target Behavior

- Run the adapter compatibility gate against a real Postgres database before hosted deployment.
- Add stronger database-level constraints where practical without weakening SQLite compatibility.

## Schema Notes

- Prefer UUID/binary IDs where both adapters can support readable local debugging.
- Store persisted money as signed integer cents. Do not store financial truth as floats, Decimal strings, or adapter-specific decimal columns.
- Store percentages and ratios separately using a documented Decimal-compatible representation.
- Store versioned sheet maps only after validation.
- Store leaderboard snapshots as denormalized columns sufficient for ranking and recap.
- Add `lock_version` or an equivalent optimistic concurrency field to mutable game/player sheet records.

## Acceptance

- SQLite migrations run through `mix setup` and test setup.
- Changeset tests cover invalid status, duplicate colors, duplicate names, invalid event type, and invalid sheet version.
- Transaction tests prove partial writes roll back.
- Stale update tests prove older sheet drafts cannot overwrite newer records.
- Restore tests prove completed-game snapshots remain immutable after import.
