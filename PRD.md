# Cashflow Live Product Requirements

## 1. Background And Objective

Cashflow Live is a local-first Phoenix LiveView app for running Cashflow board-game nights without paper math. It keeps game state durable in SQLite, makes the Elixir domain model the source of truth, and gives players a usable shared-screen workflow from setup through completed recap.

The retired Vue/Koa prototype proved the product shape but was removed from tracked runtime after the Phoenix flow reached a playable round.

## 2. Goals

- Host can create a 2-6 player game and open the shared dashboard quickly.
- Every committed sheet change is validated, persisted, and audited transactionally.
- Rat Race and Fast Track sheets use one server-side calculation model.
- Completed games become read-only and produce immutable leaderboard snapshots.
- Local backup/export is available without accounts, cloud sync, or internet multiplayer.

## 3. Non-Goals

- Authentication, authorization, cloud sync, or internet multiplayer.
- Strict official board-game enforcement beyond sheet integrity, phase transition guardrails, and completion snapshots.
- A JavaScript SPA runtime.
- Hosted deployment before the Postgres compatibility gate exists.

## 4. Current Experience Requirements

### Lobby

- Shows active and completed games.
- Links to setup, dashboard, audit, and leaderboard views.
- Keeps completed games visually distinct from active games.

### New Game Setup

- Creates games with 2-6 players.
- Requires unique player names and colors.
- Creates deterministic default sheet state for each player.

### Dashboard

- Shows player summaries for cash, passive income, income, expenses, cashflow, and phase.
- Offers `Open Sheet`, Fast Track transition when eligible, completion, audit, and backup navigation.
- Completed dashboards are read-only.

### Player Sheet

- Supports draft edits, review-before-save, save/cancel, validation errors, notes, and stale-tab conflict handling.
- Uses Rat Race fields for Rat Race players and Fast Track fields for Fast Track players.
- Keeps financial calculations in the domain layer, not in LiveViews.

### Audit And Corrections

- Records every committed turn, correction, phase transition, and completion event.
- Stores before/after snapshots, field paths, notes, origin metadata, and lock-version metadata.
- Lets corrections originate from a same-game, same-player audit event.

### Completion And Leaderboard

- Completes a game with a winner and optional comment.
- Captures immutable leaderboard records for every player at completion time.
- Provides a read-only recap path for completed games.

### Backup

- Exports games, players, audit events, leaderboard records, schema version, and export timestamp as JSON.
- Restore/import is future work.

## 5. Data Model

| Entity | Responsibility |
| --- | --- |
| Game | Title, lifecycle status, completion metadata |
| Player | Roster identity, phase, current versioned sheet, summary, optimistic lock |
| Audit Event | Append-only event log for turns, corrections, transitions, and completion |
| Leaderboard Record | Immutable completion snapshot used for rankings |

## 6. Technical Requirements

- Runtime: Elixir, Phoenix, LiveView, Ecto.
- UI: plain HEEx/function components/LiveComponents.
- Database: SQLite by default with Postgres-compatible schema design.
- Money storage: signed integer cents.
- Commands must run through `mise exec --`.
- Validation: `bash scripts/check-specs.sh`, `mise exec -- mix format --check-formatted`, and `mise exec -- mix test`.

## 7. Backlog

- Dense investment editing for real estate, businesses, stocks, and Fast Track investment rows.
- Field-label polish for audit/correction diffs.
- Backup restore/import.
- Postgres compatibility gate.
- Desktop/tablet/phone design review screenshots.
