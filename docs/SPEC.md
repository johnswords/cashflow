# Cashflow Rewrite Repository Spec

Last Verified: 2026-05-27
Status: Target specification
Truth Mode: Mixed current-state inventory and target-mode rewrite contract

## Purpose

This repository currently contains a Vue 2 + Koa + SQLite multiplayer Cashflow app. The next implementation target is a full rewrite in Elixir, Phoenix, LiveView, Ecto, and SQLite/Postgres-compatible persistence.

The rewrite should preserve the useful product primitives, discard the fragile frontend/runtime stack, and make the server-side domain model the source of truth for a complete game round.

## Current-State Truth

- The current app is a Vue 2/Vuex frontend with a Koa/Kysely/better-sqlite3 backend.
- The current data model includes `games`, `players`, `audit_log_entries`, and `leaderboard_records`.
- Existing sheet modules provide useful domain inventory: income, expenses, liabilities, assets, investments, meta, and fast track state.
- The current runtime is not trusted as the long-term implementation. Known tracked risks are captured in `docs/legacy-app-risk-inventory.md`.
- `README.md`, `PRD.md`, and `TODO.md` describe shipped or intended Vue-era behavior. Rewrite work should use this spec hierarchy as the target contract.

## Target Architecture

- Runtime: Elixir + Phoenix.
- UI: Phoenix LiveView with plain HEEx, function components, and stateful LiveComponents where they materially reduce local UI complexity.
- Persistence: Ecto schemas and migrations. SQLite is the default local and family-night database; Postgres compatibility is required for future hosted deployment.
- Client model: server-rendered HTML over LiveView. No Vue, Vite, Svelte, LiveSvelte, React, or SPA shell in the v1 rewrite.
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

## Explicit Non-Goals For Rewrite v1

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

The Phoenix rewrite must eventually prove this spec with:

- `mix format --check-formatted`
- `mix test`
- Ecto migration tests against SQLite by default.
- A Postgres compatibility check before any hosted deployment path is accepted.
- LiveView tests for create game, sheet edit, correction, completion, recap, and leaderboard flows.
- Stale-session/conflict tests for multiple browser tabs editing the same player sheet.
- Manual design review screenshots for desktop, tablet, and phone viewports before replacing the current app.

## Implementation Order

1. Scaffold Phoenix + LiveView + Ecto with SQLite-first local configuration and Postgres-compatible migrations.
2. Build the game-domain context and calculation tests before designing the sheet UI.
3. Implement Ecto schema, migration, and seed/demo data.
4. Build LiveView flows from lobby to completed recap.
5. Add backup/export and operational guardrails.
6. Migrate or archive existing SQLite data only after the target schema is stable.
