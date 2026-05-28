# LiveView Session And Concurrency

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/web/SPEC.md`, `docs/specs/persistence/ecto-schema-and-migrations.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- The v1 app is a trusted local household app with no account login.
- Browser sessions store normal Phoenix session data, not durable authorization policy.
- Player sheet drafts save against the persisted player `lock_version`.
- Stale saves show a recoverable conflict panel with a reload action instead of silently overwriting newer state.
- Completed-game read-only enforcement works through the domain active-game guard and LiveView read-only controls; a stale completed-tab save reloads the completed state.
- PubSub refreshes dashboard summaries and audit timelines after successful writes.

## Target Behavior

- Future multi-device collaboration can build on PubSub, but v1 still treats optimistic locking as the correctness boundary.

## Acceptance

- Two tabs editing the same player cannot silently overwrite each other.
- A stale save shows a recoverable conflict state.
- Refreshing a LiveView reloads canonical state from the database.
- Completed-game read-only enforcement works even if a sheet tab was opened before completion.
