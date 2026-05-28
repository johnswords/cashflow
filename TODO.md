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
- [x] Strict audit field-path validation against the versioned sheet schema
- [x] Postgres compatibility gate script
- [x] Run Postgres compatibility gate against a real local Postgres database
- [ ] Explicit setup lifecycle state if setup needs to be persisted separately from active play
- [ ] Fast Track win-state enforcement before completion if required by final v1 rules
- [ ] Run Postgres compatibility gate against the hosted Postgres database before hosted deployment

## LiveView UX

- [x] Lobby, new game setup, dashboard, audit, leaderboard, and backup routes
- [x] Player sheet draft, diff review, save/cancel, stale-tab conflict handling, and notes
- [x] Fast Track route and sheet rendering
- [x] Dense full-sheet investment editing for real estate, businesses, stocks, and Fast Track investments
- [x] Correction UX field labels and origin context
- [x] Recoverable stale-sheet reload panel
- [x] Field-level parse errors for invalid sheet inputs
- [x] Mobile touch target sizing for core controls
- [x] Leaderboard shared-rank tie rendering and mobile horizontal scroll
- [x] PubSub dashboard/audit refresh after successful writes
- [x] Correction filters and load-more behavior
- [x] Visible lobby backup/export affordance
- [x] Leaderboard filters
- [x] Completion preview and richer recap/export affordances
- [x] Desktop/tablet/phone design review screenshots

## Operations

- [x] `mix setup`, `mix test`, `mix phx.server`, and `mix assets.build`
- [x] JSON backup export at `/backup.json`
- [x] Restore/import command for backup JSON
- [x] Seed/demo data
- [x] Health endpoint for runtime checks
- [ ] Legacy SQLite import only if real historical data must be preserved
