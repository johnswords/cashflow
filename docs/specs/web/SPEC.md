# Web UI Surface Spec

Last Verified: 2026-05-28
Status: Partial
Truth Mode: Current implementation plus target gaps

## Boundary

The web surface is a Phoenix LiveView application rendered with plain HEEx, function components, and LiveComponents. It owns interaction design and presentation only. It does not own game rules, calculations, persistence policy, or audit semantics.

## Current Routes

| Route | LiveView | Purpose |
| --- | --- | --- |
| `/` | `CashflowWeb.LobbyLive` | Load screen, active games, completed games, leaderboard entry |
| `/games/new` | `CashflowWeb.GameSetupLive` | New 2-6 player setup |
| `/games/{id}` | `CashflowWeb.GameLive` | Active dashboard or read-only completed recap |
| `/games/{id}/players/{player_id}` | `CashflowWeb.PlayerSheetLive` | Player sheet edit flow |
| `/games/{id}/audit` | `CashflowWeb.AuditLive` | Audit timeline and correction launch |
| `/leaderboard` | `CashflowWeb.LeaderboardLive` | Ranked completion snapshots |

## Component Strategy

- Use function components for stateless controls, panels, money fields, badges, tabs, and summary rows.
- Use LiveComponents for localized state such as sheet sections, modals, diff review, and nested investment editors.
- Avoid LiveComponents when a plain function component plus parent LiveView state is simpler.
- Keep route-level LiveViews small by delegating business operations to contexts.
- Use JS hooks only for browser APIs such as audio playback, focus management edge cases, or measured scrolling.
- Introduce Svelte/LiveSvelte only through the repo-level ADR trigger in `docs/SPEC.md`.

## Session And Concurrency Model

- v1 assumes a trusted local household app with no account login.
- LiveView session data may carry browser preferences, return paths, and anti-forgery/session mechanics supplied by Phoenix.
- Game access is not an authorization boundary in v1.
- Each editable player sheet draft has a baseline version. Saving against a stale baseline shows a conflict instead of overwriting newer persisted state.
- Dashboard and audit LiveViews subscribe to game updates and refresh after successful game writes. Transactional conflict checks still own correctness.

## Design Invariants

- The first screen is the usable app, not a marketing page.
- The player sheet must be playable on desktop, tablet, and phone without viewport traps.
- Persistent controls must be visible on touch devices; no hover-only actions.
- Numeric money fields use tabular alignment and clear invalid/dirty/saved states.
- Arcade styling is allowed as flavor, but body text, form controls, and tables must prioritize legibility.
- Every modal has an explicit title, primary action, secondary action, escape behavior, and focus return.
- Completed games render read-only controls and recap affordances.

## Feature Specs

- `liveview-game-lobby.md`
- `new-game-setup.md`
- `active-game-dashboard.md`
- `player-turn-sheet.md`
- `audit-corrections.md`
- `end-game-and-recap.md`
- `leaderboard.md`
- `liveview-session-and-concurrency.md`

## Acceptance

- LiveView tests cover every target route.
- Keyboard users can create, edit, correct, complete, and review a game.
- Mobile screenshots show usable sheet content and fixed controls without overlap.
- No view duplicates cashflow calculations.
- Stale browser tabs cannot silently overwrite a newer sheet save.

## Target Gaps

- Optional UI polish remains, but correction filters/load-more, leaderboard filters, completion preview, and completed recap/export affordances are implemented.
