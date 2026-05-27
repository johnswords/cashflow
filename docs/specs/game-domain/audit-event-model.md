# Audit Event Model

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | `Cashflow.Audit`, Ecto schema, transactional writes |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `versioned-sheet-state.md`, `docs/specs/persistence/ecto-schema-and-migrations.md` |
| Truth Mode | Target |

## Problem

The current audit flow captures useful diffs but stores arbitrary snapshots and can mutate local canonical state before a correction is confirmed.

## Target Behavior

- Audit events are append-only.
- Event types include `turn`, `correction`, `phase_transition`, and `completion`.
- Field paths are validated against the versioned sheet schema.
- Diffs store changed paths and before/after values, not unbounded arbitrary blobs by default.
- Full snapshots are allowed only as versioned, validated recovery payloads.
- Corrections reference a same-game, same-player origin event.
- Starting a correction creates a draft; canonical state changes only after confirmation.

## Acceptance

- Saving a turn without changes is rejected or explicitly recorded as a no-op note, never as a misleading diff.
- Correction origin validation rejects cross-game and cross-player references.
- Audit timeline can reconstruct the human-readable sequence of a game without reading mutable current sheet state.
- A completed game rejects new audit events except export/read operations.
