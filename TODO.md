# Cashflow Multiplayer TODO

## Backend
- [x] SQLite schema & migration setup
- [x] Koa service scaffolding with health/games/leaderboard routes
- [x] Frontend API client wrapper
- [ ] Seed script with sample game data (optional)

## State Management
- [x] Replace localStorage persistence with backend-driven Vuex store
- [x] Add actions for games, players, audit log, leaderboard
- [x] Wire optimistic update + diff-builder for confirmation modals
- [ ] Persist audio preference (localStorage or backend profile)

## Frontend Views
- [x] Retro load screen with New Game / List Games / Leaderboard menu
- [x] New Game flow: player count, names, color selection
- [x] Games list view with resume + end game entry points
- [x] Game dashboard showing player financial summaries + recent changes
- [x] Player sheet view using existing RatRace/FastTrack components with save/cancel
- [x] Audit log modal with correction flagging
- [x] Leaderboard view with shared-rank display
- [ ] Leaderboard polish (filters, recap navigation, visual refresh)

## UX Enhancements
- [x] Confirmation modals summarizing diffs before saves
- [x] Winner flow with comment capture + snapshot display
- [x] SNES/GameCube audio cues (save + victory) with mute toggle
- [ ] Friendly labels for nested field paths (investments, fast track)
- [ ] Add CRT/animation polish and idle tips for load screen

## Future / Stretch
- [ ] Timer instrumentation hooks (game + turn)
- [ ] Responsive tuning for 1080p shared screens
- [ ] Animations and additional sound effects
- [ ] Export game history (JSON / CSV)
