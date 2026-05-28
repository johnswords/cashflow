# New Game Setup

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `docs/specs/game-domain/versioned-sheet-state.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Host chooses a title, 2-6 populated player rows, player names, colors, and optional professions.
- Names and colors are required for populated rows and unique within the game.
- Submitting creates the game, players, and default sheet states in one transaction.
- Successful creation redirects to `/games/{id}`.

## Target Behavior

- The setup form validates live with Ecto changesets.
- Initial audit seed events should be added only if the product still needs explicit setup audit entries.

## Acceptance

- A two-player and six-player game can be created from tests.
- Duplicate names or colors show inline validation and do not create records.
- Successful creation redirects to `/games/{id}`.
