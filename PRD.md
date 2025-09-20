# Cashflow Balance Sheet Multiplayer – Product Requirements v1.1 (Draft)

## 1. Background & Objective
- Evolve the single-player cashflow sheet into a persistent, multi-player experience backed by SQLite so multiple games and player states can be stored, resumed, and audited.
- Deliver a nostalgic “classic Nintendo” presentation layer with a load screen and arcade-style navigation while preserving the fidelity of Rich Dad Cashflow calculations.

## 2. Goals & Success Criteria
- A host can create a new game, configure players, and reach the shared game screen in ≤ 2 minutes with zero manual file edits.
- Any game state change is persisted to SQLite immediately and can be resumed from the load screen with no loss of data.
- Audit trail surfaces every modification with enough context to recreate, undo, or correct it without ambiguity.
- Leaderboard automatically surfaces top finishing cashflow scores from completed games.

## 3. Non-Goals
- Enforcing turn order, simultaneous play, or real-time sync across devices.
- Multi-session collaboration (single operator sessions only for v1).
- Advanced financial modeling beyond what the current sheet already computes.
- Additional game lifecycle actions such as archive, delete, or rename flows.

## 4. Target Users & Scenarios
- Primary: Henry + friends/family playing Cashflow in one physical space using a shared screen.
- Secondary: Facilitators running multiple games and wanting quick recall of past sessions.

## 5. Experience & Flow Requirements

### 5.1 Boot / Load Screen
- Presents three primary actions: `New Game`, `List Games`, `Leaderboard`.
- Styling cues: CRT scanline filter, 8-bit type, animated highlight cursor, simple chiptune loop (optional stretch).
- Background shows rotating tips or the Cashflow rat illustration (asset TBD).
- Keyboard/controller support: arrow keys + enter/escape map to selection + back.

### 5.2 New Game Setup
- Step 1: Prompt for game title (optional, defaults to “Game <timestamp>”), date/time auto-stamped.
- Step 2: Select number of players (2–6). Enforce unique color assignment from palette {blue, purple, orange, red, green, yellow}.
- Step 3: For each player collect name (required) and assign color.
- Confirmation screen summarizes configuration before creation.
- On create: generate unique `game_id`, instantiate each player with base sheet values cloned from current single-player defaults.

### 5.3 List Games
- Sorted by last updated descending.
- Card/table view exposes `game name`, `created_at`, `last_played`, player list, completion status.
- Actions per game: `Resume`, `View Audit Log`, `End Game` (disabled if already ended).

### 5.4 Game Screen
- Top area: breadcrumb back to load screen, game title, timestamp, status badge (Active/Completed).
- Player grid cards show: name, color tag, cash, monthly salary, passive income, total income, total expenses, kid count & per-child cost, net monthly cashflow.
- Recent changes panel lists latest N audit entries per player (configurable, default 5) with link to full log modal.
- CTA per player: `Open Sheet`. Optionally highlight players with negative cashflow.
- Global actions: `End Game`, `Back to Load Screen`.
- All state-changing interactions require confirmation modal summarizing the diff.

### 5.5 Player Sheet View
- Reuse existing single-player sheet layout with the following additions:
  - Player header (name, color, current cashflow summary).
  - `Save & Return to Game` button (primary) that plays a short retro confirmation sound on success.
  - `Cancel & Return` button; if unsaved changes exist, prompt before discard.
  - On save: validate inputs, persist via API/store, append audit entry, update last modified timestamp.

### 5.6 Audit Log
- Accessible via game screen (`View All Changes`) and per-player cards.
- Table columns: timestamp, player, field(s) changed, concise change summary (e.g., “Expenses → Housing: 1500 → 1800”), entry type (`turn` vs `correction`), optional note.
- Corrections log identically to other moves but tagged as “Correction / Adjusting Entry”; they reference the original entry ID when applicable.
- Clicking an entry opens the sheet pre-populated with the post-change state for review/edit.

### 5.7 End Game Flow
- Triggered from game screen or list view.
- Modal prompts to select winning player and capture optional comment; confirm final snapshot.
- After confirmation: lock game to read-only, capture final stats snapshot (per-player cashflow et al.) for leaderboard ingestion, mark `completed_at`, and play winner fanfare sound.

### 5.8 Leaderboard
- Displays top N player results ranked by final net monthly cashflow from completed games only.
- Each row shows player name, cashflow value (formatted in USD), associated game title, game completion date, and winner comment if present.
- If multiple entries share identical cashflow values, rank by earliest completion date while allowing shared numeric rank.
- Supports filtering by timeframe (e.g., last 10 games, last 90 days) and optionally by player.
- Clicking a row opens the completed game in read-only mode.

## 6. Data & Persistence Model (SQLite)
- **Game**
  - `id` (UUID), `title`, `created_at`, `updated_at`, `completed_at?`, `status` (`active`/`completed`), `winner_player_id?`, `winner_comment?`
- **Player**
  - `id` (UUID), `game_id`, `name`, `color`, `sheet_state` (JSON), `last_modified_at`
- **AuditLogEntry**
  - `id` (UUID), `game_id`, `player_id`, `timestamp`, `entry_type` (`turn`/`correction`), `field_paths[]`, `before_snapshot` (JSON diff or compact structure), `after_snapshot` (JSON diff), `notes?`, `origin_entry_id?`
- **LeaderboardRecord**
  - `id`, `game_id`, `player_id`, `cashflow_value`, `captured_at`, `winner_comment?`
- SQLite hosted locally via lightweight Node service (e.g., Koa/Express + better-sqlite3/Kysely). Schema migrations tracked in repo.

## 7. Business Rules & Validation
- Net income = total income − total expenses; derived, not directly editable.
- Kids count limited to non-negative integers; per-child cost ≥ 0.
- Prevent duplicate player names within a game unless override setting introduced later.
- Confirmation modal must display human-readable diff (e.g., “Expenses → Housing: 1500 → 1800”).
- Maximum players per game: six (one per color). Colors cannot be reused in the same game.
- Games cannot re-open once ended without duplication.

## 8. Technical & Architectural Requirements
- Vue 2 frontend continues to use Vuex; introduce modules for `games`, `players`, `audit`.
- Create API/service layer:
  - Node process exposes REST or IPC endpoints for CRUD operations backed by SQLite.
  - Ensure ACID compliance for multi-entity updates (e.g., player sheet update + audit entry + game updated_at in single transaction).
- Implement optimistic UI updates with rollback on failure.
- Provide seed script for initial schema setup and migration runner for future evolution.
- Audio assets loaded via webpack; provide simple utility to play “save” and “victory” cues with volume control.

## 9. UX, Audio & Accessibility
- Keyboard navigation for all flows; highlight focus states consistent with retro theme.
- Color palette must meet minimum contrast for text overlays (>4.5:1).
- Audio cues:
  - Save success: short SNES/GameCube-era style confirmation (<1 second) with quick decay.
  - Game win: brief celebratory fanfare (≤3 seconds) matching the same aesthetic.
  - Provide mute toggle in settings.
- Confirmation modals include explicit primary/secondary buttons and summary copy.

## 10. Telemetry & Logging (Optional v1)
- Console logging toggle for debugging game state changes.
- Consider hook for exporting game history as JSON/CSV.

## 11. Testing & Acceptance
- Critical manual paths: game creation, resume, per-player sheet save (with sound), audit log correction tagging, end game snapshot, leaderboard update.
- Minimum manual test matrix: Chrome latest, Safari latest on macOS.
- Future automated coverage: Vue Test Utils specs for flows; integration tests for SQLite persistence layer (Node-side).

## 12. Open Questions & Assumptions
- Audio asset sourcing/licensing: confirm whether we compose in-house, source royalty-free, or integrate existing assets.
- Winner comment length limits (e.g., 140 characters) still TBD.

## 13. Future Features (Backlog)
- Game Timer: track how long an active game session is open.
- Turn Timer: track per-player sheet duration before returning to main screen.
- Expanded sounds and screen animations (e.g., turn transitions, leaderboard reveal).
- 1080p shared-screen layout refinements (responsive typography, spacing, safe zones).
