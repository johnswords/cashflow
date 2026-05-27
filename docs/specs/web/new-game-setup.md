# New Game Setup

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | `CashflowWeb.GameSetupLive` |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/versioned-sheet-state.md` |
| Truth Mode | Target |

## Target Behavior

- Host chooses a title, player count from 2-6, player names, colors, and optional professions.
- Names are required and unique within the game.
- Colors are required and unique within the game.
- The setup form validates live with Ecto changesets.
- Submitting creates the game, players, default sheet states, and initial audit seed events in one transaction.

## Acceptance

- A two-player and six-player game can be created from tests.
- Duplicate names or colors show inline validation and do not create records.
- Successful creation redirects to `/games/{id}`.
