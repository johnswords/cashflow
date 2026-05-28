# Cashflow Live TODO

## Current Runtime

- [x] Phoenix LiveView app scaffolded at the repo root
- [x] Runtime pinned with `mise`
- [x] SQLite dev/test configuration wired through Ecto
- [x] Vue/Koa runtime removed from tracked source

## Domain And Persistence

- [x] Signed integer-cent money parsing and display
- [x] Versioned Rat Race and Fast Track sheet state
- [x] Domain calculations and golden formula tests
- [x] Ecto schemas and migrations for games, players, audit events, and leaderboard records
- [x] Transactional saves, corrections, phase transitions, completion, and leaderboard snapshots
- [x] Completed-game immutability tests
- [ ] Postgres compatibility gate before hosted deployment

## LiveView UX

- [x] Lobby, new game setup, dashboard, audit, leaderboard, and backup routes
- [x] Player sheet draft, diff review, save/cancel, stale-tab conflict handling, and notes
- [x] Fast Track route and sheet rendering
- [ ] Dense full-sheet investment editing for real estate, businesses, stocks, and Fast Track investments
- [ ] Correction UX polish with field labels and origin context
- [ ] Desktop/tablet/phone design review screenshots

## Operations

- [x] `mix setup`, `mix test`, `mix phx.server`, and `mix assets.build`
- [x] JSON backup export at `/backup.json`
- [x] Seed/demo data
- [ ] Restore/import command for backup JSON
- [ ] Legacy SQLite import only if real historical data must be preserved
