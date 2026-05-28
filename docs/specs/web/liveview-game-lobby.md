# LiveView Game Lobby

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/web/SPEC.md`, `docs/specs/game-domain/SPEC.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Shows primary actions for new game, active games, completed recaps, and leaderboard.
- Lists resumable active games by most recently updated.
- Lists completed games as recap links.
- Shows empty states with direct actions.

## Target Behavior

- Add a visible local backup/export affordance.
- Shows database health and backup freshness only where useful to the host.

## Acceptance

- Clicking an active game opens `/games/{id}` in active dashboard mode.
- Clicking a completed game opens `/games/{id}` in read-only recap mode.
- The lobby remains usable with zero games, many active games, and many completed games.
