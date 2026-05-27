# LiveView Game Lobby

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | `CashflowWeb.LobbyLive` |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/web/SPEC.md`, `docs/specs/game-domain/SPEC.md` |
| Truth Mode | Target |

## Target Behavior

- Shows primary actions for new game, active games, completed games, leaderboard, and local backup/export.
- Lists resumable active games by most recently updated.
- Lists recent completed games as recap links, not mutable resume links.
- Shows empty states with direct actions.
- Shows database health and backup freshness only where useful to the host.

## Acceptance

- Clicking an active game opens `/games/{id}` in active dashboard mode.
- Clicking a completed game opens `/games/{id}` in read-only recap mode.
- The lobby remains usable with zero games, many active games, and many completed games.
