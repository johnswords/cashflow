# Cashflow Multiplayer TODO

## Backend
- [x] SQLite schema & migration setup
- [x] Koa service scaffolding with health/games/leaderboard routes
- [x] Frontend API client wrapper
- [ ] Seed script with sample game data (optional)

## State Management
- [x] Replace localStorage persistence with backend-driven Vuex store
- [x] Add actions for games, players, audit log, leaderboard
- [ ] Wire optimistic update + diff-builder for confirmation modals

## Frontend Views
- [ ] Retro load screen with New Game / List Games / Leaderboard menu
- [ ] New Game flow: player count, names, color selection
- [ ] Games list view with resume + end game entry points
- [ ] Game dashboard showing player financial summaries + recent changes
- [ ] Player sheet view using existing RatRace/FastTrack components with save/cancel
- [ ] Audit log modal with correction flagging
- [ ] Leaderboard view with shared-rank display

## UX Enhancements
- [ ] Confirmation modals summarizing diffs before saves
- [ ] Winner flow with comment capture + snapshot display
- [ ] SNES/GameCube audio cues (save + victory) with mute toggle

## Future / Stretch
- [ ] Timer instrumentation hooks (game + turn)
- [ ] Responsive tuning for 1080p shared screens
- [ ] Animations and additional sound effects
