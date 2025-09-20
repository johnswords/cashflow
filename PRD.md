# Cashflow Balance Sheet Multiplayer – Product Requirements v1.2 (Working)

## 0. Revision Snapshot (September 20, 2025)
- Load screen, game dashboard, player sheet workflow, audit modal, end-game flow, and audio toggle are implemented.
- Leaderboard exists (backend + basic view) but requires polish and richer UX.
- Timers, responsive 1080p layout, and expanded animations remain backlog items.

## 1. Background & Objective
- Extend the original single-player Cashflow worksheet into a persistent, multi-player experience with an unmistakable retro arcade feel.
- Retain Rich Dad Cashflow math while adding guardrails (diff confirmations, audit trail, corrections, winner ceremony) to make live game nights effortless.

## 2. Goals & Success Criteria
- ✅ Host creates a new game, configures 2–6 players, and lands on the shared dashboard in ≤ 2 minutes without manual data entry.
- ✅ Every sheet change persists immediately to SQLite and can be resumed from the load screen without data loss.
- ✅ Audit log captures field-level diffs, identifies corrections, and supports rewinding to prior state.
- 🔄 Leaderboard highlights top finishing cashflow scores with contextual detail (snapshot, comment, completion date) and easy navigation back to completed games.
- 🎯 Experience runs comfortably on a shared 1080p display with SNES/GameCube-style audiovisual cues.

## 3. Non-Goals (v1)
- Enforcing strict turn order, multi-device sync, or online multiplayer.
- Complex financial modelling beyond the existing worksheet calculations.
- Game archival/deletion workflows (duplicate to restart if needed).
- Authentication/authorization or cloud sync.

## 4. Target Users & Scenarios
- **Primary:** Henry + family/friends running Cashflow nights on a single large screen.
- **Secondary:** Facilitators wanting to store multiple sessions and review prior adjustments.

## 5. Experience Requirements

### 5.1 Load Screen (Implemented)
- Actions: `New Game`, `List Games`, `Leaderboard`.
- Retro styling with keyboard navigation (arrow / enter / esc).
- Audio toggle persists preference across major screens.

### 5.2 New Game Setup (Implemented)
- Steps: title (optional), player count (2–6), per-player name + unique color (blue, purple, orange, red, green, yellow).
- Validation: names required/unique, colors unique, live error states.
- On confirm: creates `game_id`, clones default sheet state, auto-selects first player.

### 5.3 Games List (Implemented)
- Sorted by `updatedAt` desc with status badge (Active/Completed).
- Shows player roster, last played, quick actions: `Resume`, `Audit Log`, `End Game` (if active).
- Refresh control to re-fetch backend state.

### 5.4 Game Dashboard (Implemented)
- Player cards display: name, color, cash, salary, passive income, total income/expenses, cashflow, kid count.
- Recent changes panel (latest 3 audit entries per player) with human-friendly field labels.
- Actions: `Open Sheet`, `Audit Log` (modal), `End Game` (modal).
- Audio toggle in header.

### 5.5 Player Sheet View (Implemented)
- Reuses Rat Race & Fast Track layouts.
- Controls: `Back`, `Switch Sheet`, `Save & Return`, global audio toggle.
- Save confirmation modal lists field-level diffs, allows marking corrections (auto-checked when invoked from audit log).
- Saving emits audit entry, plays “save” chime, and resets baseline state.

### 5.6 Audit Log Modal (Implemented)
- Columns: timestamp, player, entry type (`turn` vs `correction`), field list.
- Filters by player; paginated fetch (50 entries with “Load More”).
- “Correct” shortcut preloads historical snapshot and opens sheet for editing (logs new correction entry).

### 5.7 End Game Flow (Implemented)
- Modal selects winner, preview of final stats (cash, passive income, totals, cashflow), optional comment.
- On confirm: auto-saves snapshot to leaderboard, updates game status, plays victory fanfare, closes modal.

### 5.8 Leaderboard View (MVP Complete – Needs Polish)
- Shows ranked list (shared ranks for ties) filtered to completed games, sorted by cashflow desc + completion date.
- Winner comment shown inline; row click loads completed game read-only (future: open in recap view).
- Next iteration: styling refresh, filter controls (timeframe/player), completed-game read-only view.

## 6. Data & Persistence Model (SQLite)
| Entity | Fields |
| --- | --- |
| Game | `id`, `title`, `status`, `created_at`, `updated_at`, `completed_at`, `winner_player_id`, `winner_comment` |
| Player | `id`, `game_id`, `name`, `color`, `sheet_state` (JSON), `last_modified_at` |
| AuditLogEntry | `id`, `game_id`, `player_id`, `timestamp`, `entry_type`, `field_paths[]`, `before_snapshot` (JSON), `after_snapshot` (JSON), `notes?`, `origin_entry_id?` |
| LeaderboardRecord | `id`, `game_id`, `player_id`, `cashflow_value`, `captured_at`, `winner_comment?` |

Implementation details:
- WAL enabled, foreign keys enforced.
- Kysely migrations under `src/backend/db/migrations`.
- Transactions required for sheet save (player update + audit entry + game timestamp).

## 7. Business Rules & Validation
- Derived values (net income, cashflow) are read-only; store computed totals in UI only.
- Player names and colors must be unique within a game.
- Audit entries require at least one `field_path`; corrections reference `origin_entry_id`.
- Games are immutable once completed; duplicate to restart.
- Audio preference defaults to enabled, stored in Vuex (future: persist per browser).

## 8. Technical Requirements
- Vue 2 + Vuex; new views live under `src/components/app/`.
- REST API served from `src/backend/server.js` using Koa, `@koa/router`, `koa-bodyparser`.
- Zod schemas for payload validation (`src/backend/validators`).
- Utility helpers:
  - `src/utils/diff.js` – sheet diff builder for audit entries.
  - `src/utils/cashflow.js` – financial summaries.
  - `src/utils/audio.js` – Web Audio engine with SNES-style tones and mute toggle.
- Dev proxy in `vue.config.js` routes `/api` to `http://localhost:4000`.
- Data directory `data/` must exist (created automatically) and remain gitignored.

## 9. UX, Audio & Accessibility
- Retro palette, high-contrast gradients, `Press Start 2P` font.
- Keyboard navigation across major flows; buttons have visible focus states.
- Audio cues: save (two-tone blip, <0.2s), victory (4-note arpeggio, <1s). Global toggle present on load screen, dashboard, player sheet.
- Modals always include explicit primary/secondary actions; confirmation modals show diff summaries.
- Future: integrate subtle CRT overlay and optional chiptune loop on load screen (opt-in).

## 10. Telemetry & Logging (Future Consideration)
- Provide debug flag to console-log API requests/responses for live sessions.
- Export/backup feature (JSON or CSV) remains a backlog item.

## 11. Testing & Acceptance
- Manual regression (until automated tests exist):
  1. New game creation (2, 6 players) → ensure color uniqueness errors.
  2. Sheet save diff detection, correction save from audit log.
  3. End game snapshot, verify leaderboard row, audio cues fire.
  4. Resume completed game via list → game screen shows read-only state.
- Automated roadmap: Vue Test Utils for view flows, backend integration suite using sqlite in-memory.

## 12. Open Questions & Assumptions
- Leaderboard UX: Should completed games open in read-only sheet view or a dedicated recap screen?
- Recent change labeling: need friendly strings for nested investment fields (e.g., `investments.realEstate[0].income`).
- Audio persistence: store preference in localStorage? (Current session-only)
- Winner comment length limit (default 280 chars). Confirm acceptable.

## 13. Backlog & Enhancements
1. **Leaderboard polish** – filters, navigation back to recap, visual upgrades.
2. **Timing metrics** – game duration + per-player turn timers (surface on dashboard + export).
3. **Responsive pass** – tuned typography/margins for 1080p shared screens & tablets.
4. **Animations & FX** – transition states, idle tips carousel, CRT effects.
5. **Data export** – download JSON/CSV of game history for archival.
6. **Seed data** – optional command to create demo game for screenshots/testing.
