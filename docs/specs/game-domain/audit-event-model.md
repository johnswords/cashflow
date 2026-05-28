# Audit Event Model

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-28 |
| Linear Issue | TBD |
| Depends On | `versioned-sheet-state.md`, `docs/specs/persistence/ecto-schema-and-migrations.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Audit events are persisted append-only through `Cashflow.Games.AuditEvent`.
- Event types include `turn`, `correction`, `phase_transition`, and `completion`.
- Turn, correction, phase transition, and completion writes happen inside domain transactions.
- Correction saves require a same-game, same-player origin event.
- Starting a correction from the audit timeline opens a player-sheet draft with `origin_event_id`; canonical state changes only after save.
- Saving a turn or correction without changes is rejected as `:no_changes`.
- Audit event field paths are validated against the versioned sheet schema, with explicit allowances for game-level completion fields.
- Player-sheet review and audit timeline views display friendly field labels while preserving raw paths in title/secondary text.
- Audit event queries support player and event-type filters plus bounded pagination for the web timeline.

## Problem

The retired audit flow captured useful diffs but stored arbitrary snapshots and could mutate local canonical state before a correction was confirmed. The Phoenix implementation now has transactional audit writes, origin validation, schema-aware field paths, and correction context. Remaining work is mostly presentation depth and future recovery tooling.

## Target Gaps

- Full snapshots are stored as recovery payloads today; future recovery/import tooling should continue validating them against sheet versions.

## Acceptance

- Saving a turn without changes is rejected or explicitly recorded as a no-op note, never as a misleading diff.
- Correction origin validation rejects cross-game and cross-player references.
- Audit timeline can reconstruct the human-readable sequence of a game without reading mutable current sheet state.
- A completed game rejects new audit events except export/read operations.
