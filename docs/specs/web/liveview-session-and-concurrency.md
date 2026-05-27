# LiveView Session And Concurrency

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | Phoenix sessions, LiveView assigns, PubSub, sheet version checks |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/web/SPEC.md`, `docs/specs/persistence/ecto-schema-and-migrations.md` |
| Truth Mode | Target |

## Target Behavior

- The v1 app is a trusted local household app with no account login.
- Browser sessions store only normal Phoenix session data and local preferences, not durable authorization policy.
- A player sheet draft records the persisted sheet version or timestamp it was loaded from.
- Saving compares that baseline with the current persisted sheet.
- If the sheet changed elsewhere, the save returns a conflict with enough detail to reload, compare, or abandon the draft.
- PubSub broadcasts update dashboard summaries and audit timelines after successful writes.

## Acceptance

- Two tabs editing the same player cannot silently overwrite each other.
- A stale save shows a recoverable conflict state.
- Refreshing a LiveView reloads canonical state from the database.
- Completed-game read-only enforcement works even if a sheet tab was opened before completion.
