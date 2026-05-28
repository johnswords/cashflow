# Audit Timeline And Corrections

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/audit-event-model.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Shows a chronological audit timeline with player, event type, notes, changed field paths, and correction launch links.
- Completed games hide correction launch buttons.
- Starting a correction opens the player sheet with `origin_event_id`.
- Correction drafts show the origin event, original note, and friendly labels for changed fields.
- Audit timeline badges show friendly field labels while preserving raw paths in badge titles.
- Confirming a correction writes a correction event and updates the player sheet transactionally.

## Target Behavior

- Filters by player and event type.
- Loads more events without disorienting scroll position.

## Acceptance

- A canceled correction leaves dashboard and persisted state unchanged.
- A correction links back to the origin event.
- Completed games show audit read-only.
