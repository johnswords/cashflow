# Cashflow Rewrite Repository Spec

Last Verified: 2026-05-27
Status: Current Phoenix implementation with target/deferred follow-up
Truth Mode: Current implementation plus retained target invariants

## Purpose

This repository contains a Phoenix LiveView Cashflow app implemented in Elixir, Phoenix, LiveView, Ecto, and SQLite/Postgres-compatible persistence patterns.

The app preserves the useful product primitives from the retired Vue/Koa prototype while making the server-side domain model the source of truth for a complete game round.

## Current-State Truth

- The active runtime is Phoenix LiveView with Ecto-backed SQLite local persistence.
- The current data model includes `games`, `players`, `audit_events`, and `leaderboard_records`.
- Current sheet modules provide income, expenses, liabilities, assets, investments, meta, and fast track state.
- Current game statuses are `active` and `completed`; a separate persisted setup status remains target-state only.
- The retired Vue/Koa runtime is removed from tracked source. Known historical risks are captured in `docs/legacy-app-risk-inventory.md`.
- `README.md`, `PRD.md`, and `TODO.md` now describe the Phoenix implementation and follow-up work. This spec hierarchy remains the target contract.

## Architecture

- Runtime: Elixir + Phoenix.
- UI: Phoenix LiveView with plain HEEx, function components, and stateful LiveComponents where they materially reduce local UI complexity.
- Persistence: Ecto schemas and migrations. SQLite is the default local and family-night database; Postgres compatibility is required for future hosted deployment.
- Client model: server-rendered HTML over LiveView. No Vue, Vite, Svelte, LiveSvelte, React, or SPA shell in the v1 app.
- Domain model: Elixir contexts own game lifecycle, sheet calculations, validation, audit events, leaderboard snapshots, and backups.
- Assets: CSS and light JavaScript hooks only where LiveView cannot provide the interaction ergonomically.

## Glossary

- Game: a 2-6 player Cashflow session with setup, active, or completed lifecycle state.
- Player: a participant in one game with a roster identity, color, profession, phase, and current sheet.
- Sheet: the versioned financial state for one player.
- Rat Race: the initial sheet phase where the player tracks salary, passive income, recurring expenses, assets, liabilities, and children.
- Fast Track: the later sheet phase entered after passive income exceeds total expenses.
- Turn: a committed player sheet update during active play.
- Correction: a committed update derived from a prior audit event, explicitly marked as a correction.
- Recap: a read-only completed-game view backed by immutable snapshots.
- Leaderboard Record: a denormalized completion snapshot used for ranking.

## Spec Surfaces

| Surface | Spec | Responsibility |
| --- | --- | --- |
| Game Domain | `docs/specs/game-domain/SPEC.md` | Cashflow rules, sheet state, calculations, phases, audit semantics |
| Web UI | `docs/specs/web/SPEC.md` | LiveView routes, HEEx views, components, interaction states, accessibility |
| Persistence | `docs/specs/persistence/SPEC.md` | Ecto schemas, migrations, SQLite/Postgres constraints, data migration |
| Operations | `docs/specs/operations/SPEC.md` | Local setup, seed data, health checks, backup/restore, release assumptions |

## Target Invariants

- The server is the source of truth for game state. LiveView assigns are projections of Ecto-backed domain state or explicit unsaved drafts.
- All money values are parsed and stored consistently, with signed decimal support where the game permits negative values.
- Persisted money values use signed integer cents. Domain calculations may use `Decimal` internally, and percentages/ratios are separate decimal fields. Floats are not allowed for financial truth.
- Derived values such as passive income, total income, total expenses, and cashflow are calculated in one Elixir domain module.
- A game has an explicit lifecycle: setup, active, completed. Completed games are immutable except for explicit duplication/export operations.
- A player has an explicit phase: rat race or fast track. Moving to fast track requires a validated domain transition.
- Every committed sheet change produces an audit event with validated field paths, before/after values, and origin metadata.
- Corrections never mutate canonical state before the host confirms the correction.
- Leaderboard records are immutable snapshots captured at completion time.
- JSON/map fields, if used, must be versioned and validated at the context boundary.
- SQLite and Postgres must share the same logical schema and domain behavior, even where physical column types differ.
- The v1 app is a trusted local household app with no accounts. Browser session state may store preferences or draft identity only; it must not become an authorization boundary.
- Multiple tabs are allowed but not considered collaborative multiplayer. Stale saves must be detected with versioning or updated timestamps and resolved with an explicit conflict flow.

## Svelte And Custom JavaScript Rule

Plain LiveView, HEEx, function components, LiveComponents, and Phoenix JS commands are the default. A Svelte/LiveSvelte component or larger custom JavaScript island requires an ADR-style note that names the failed LiveView interaction, the user-visible need, the rejected alternatives, and the maintenance boundary.

## Product Primitives To Preserve

- Create and resume 2-6 player games.
- Unique player names and colors per game.
- Rat Race and Fast Track sheet modes.
- Income, expenses, liabilities, assets, real estate, businesses, stocks, and children.
- Diff confirmation before saving a turn.
- Audit timeline with correction flow.
- Recent activity summaries.
- Winner selection, completion ceremony, immutable recap, and leaderboard.
- Local single-machine hosting with durable SQLite storage.

## Current Gaps And Deferred Work

- Postgres compatibility is a target gate before any hosted deployment; the current runtime is SQLite-first and prod config uses `DATABASE_PATH`.
- Backup export is current at `/backup.json`; validated JSON restore/import is available through `mix cashflow.backup.restore`.
- Legacy Vue/Koa SQLite import is deferred unless real historical game data must be preserved.
- Correction writes, origin validation, friendly field labels, and correction origin context exist; filters and load-more behavior remain target polish.
- Desktop/tablet/phone design review screenshots have been captured for the current hardening pass.
- PubSub broadcasts refresh active dashboard and audit timeline views after successful game writes.

## Explicit Non-Goals For V1

- Authentication, authorization, or internet multiplayer.
- A JavaScript SPA framework.
- Strict official board-game rule enforcement beyond sheet integrity, phase transition guardrails, and win-condition checks.
- Cloud sync.
- Real-time multi-device collaboration beyond what a single Phoenix server can naturally support later.

## External Grounding

- Phoenix LiveView is the chosen interaction model because it keeps stateful UI logic on the server while rendering HTML diffs to the browser: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
- Phoenix HEEx/function components and LiveComponents are the component primitives for the rewrite: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html and https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html
- Ecto changesets, migrations, and transactions are the persistence boundary: https://hexdocs.pm/ecto/Ecto.Changeset.html and https://hexdocs.pm/ecto_sql/Ecto.Migration.html
- The SQLite adapter has documented differences from Postgres; compatibility must be tested rather than assumed: https://hexdocs.pm/ecto_sqlite3/Ecto.Adapters.SQLite3.html

## Validation Contract

The implemented Phoenix app is validated with:

- `mise exec -- mix format --check-formatted`
- `mise exec -- mix test`
- SQLite migrations run during setup and test database preparation.
- LiveView tests for lobby, setup, dashboard, sheet edit, audit, completion, backup export, and leaderboard routes.
- Domain tests for create game, sheet saves, stale draft rejection, correction origin requirements, completion, and completed-game immutability.
- Backup restore tests cover transactional import, non-empty database refusal, schema-version validation, and restored completed-game immutability.
- `scripts/check-postgres-compat.sh` is the hosted Postgres compatibility gate when `DATABASE_URL` points at a real Postgres database.

Target validation still required:

- A successful Postgres compatibility check against the actual hosted deployment database before any hosted deployment path is accepted.

## Rollout Checkpoints

1. Phoenix + LiveView + Ecto scaffolded with SQLite-first local configuration and Postgres-compatible migration discipline.
2. Game-domain context and calculation tests implemented before dense sheet UI work.
3. Ecto schema, migration, and seed/demo data implemented.
4. LiveView flows built from lobby to completed recap.
5. Backup/export and operational guardrails added.
6. Vue/Koa runtime retired from tracked source after Phoenix reached a playable round.
7. One-off legacy SQLite import remains deferred unless real historical data must be preserved.
