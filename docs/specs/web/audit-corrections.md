# Audit Timeline And Corrections

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | `CashflowWeb.AuditLive`, correction draft flow |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/audit-event-model.md` |
| Truth Mode | Target |

## Target Behavior

- Shows a chronological audit timeline with player, event type, changed fields, notes, and origin links.
- Filters by player and event type.
- Loads more events without disorienting scroll position.
- Starting a correction opens a draft based on the selected event without changing canonical state.
- Confirming a correction writes a correction event and updates the player sheet transactionally.

## Acceptance

- A canceled correction leaves dashboard and persisted state unchanged.
- A correction links back to the origin event.
- Completed games show audit read-only.
