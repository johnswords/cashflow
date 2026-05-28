# Cashflow Live

Phoenix LiveView app for Cashflow game-night sheets. The active runtime is an Elixir/Phoenix service with LiveView UI, Ecto persistence, and SQLite-first local storage. The retired Vue/Koa runtime has been removed from tracked source; historical risks and parity notes remain in `docs/legacy-app-risk-inventory.md`.

## Current Phoenix Capabilities

- Create 2-6 player games with unique names and colors.
- Persist versioned player sheet state in SQLite through Ecto.
- Calculate salary, passive income, expenses, bank-loan payment, child expenses, cashflow, and Fast Track eligibility in Elixir.
- Edit a player sheet with draft state, diff review, save/cancel, stale-save protection, and completed-game read-only enforcement.
- Capture audit events for turns, corrections, phase transitions, and completion.
- Complete games with immutable leaderboard snapshots.
- Browse lobby, dashboard, sheet, audit, leaderboard, and JSON backup/export routes.
- Restore a validated JSON backup into a fresh or replaced local database.
- Seed demo active/completed games for local review.

Not yet implemented: health endpoint, correction filtering/load-more, and real Postgres gate execution against hosted infrastructure.

## Prerequisites

- `mise`
- SQLite

Project runtime is pinned in `mise.toml`:

```bash
mise install
```

## Local Development

```bash
mise exec -- mix setup
mise exec -- mix phx.server
```

Open `http://localhost:4000`.

Game data lives in `data/cashflow_dev.sqlite3`, which is ignored.

## Useful Commands

| Command | Description |
| --- | --- |
| `mise exec -- mix setup` | Fetch deps, create/migrate DB, seed demo data, build assets |
| `mise exec -- mix test` | Run ExUnit and LiveView tests |
| `mise exec -- mix ecto.migrate` | Apply Ecto migrations |
| `mise exec -- mix phx.server` | Start the Phoenix dev server |
| `mise exec -- mix assets.build` | Build CSS/JS assets |
| `mise exec -- mix cashflow.backup.restore path/to/backup.json [--replace]` | Restore a validated JSON backup |
| `bash scripts/check-postgres-compat.sh` | Run the Postgres compatibility gate when `DATABASE_URL` is set |
| `bash scripts/check-specs.sh` | Validate the SDD spec hierarchy |

## Architecture

### Phoenix App

- `lib/cashflow/games.ex` is the public transactional boundary for games, players, audit events, leaderboard records, and backup export.
- `lib/cashflow/sheets.ex` owns versioned sheet defaults, normalization, diffing, and phase transition helpers.
- `lib/cashflow/calculations.ex` owns all money math and eligibility checks.
- `lib/cashflow/money.ex` parses and displays signed integer cents.
- `lib/cashflow_web/live/` contains the LiveView routes.
- `lib/cashflow_web/components/` contains HEEx/LiveComponent UI building blocks.
- `priv/repo/migrations/` contains the SQLite-first Ecto schema.

### Legacy Inventory

The old Vue/Koa runtime has been retired from tracked source. Use `docs/legacy-app-risk-inventory.md` and git history for historical comparison only. Do not reintroduce Node, Vue, Koa, Vite, Svelte, or another SPA runtime without an explicit ADR-style exception.

## Specification Hierarchy

The rewrite contract lives in `docs/SPEC.md` and `docs/specs/**`.

Target stack: Elixir, Phoenix, LiveView, plain HEEx/LiveComponents, Ecto, SQLite-first local persistence, and Postgres-compatible schema design.

## Backup Export

```bash
curl http://localhost:4000/backup.json
```

The export includes games, players, audit events, leaderboard records, schema version, and export timestamp.

## Backup Restore

```bash
mise exec -- mix cashflow.backup.restore path/to/backup.json
mise exec -- mix cashflow.backup.restore path/to/backup.json --replace
```

Restore validates schema version, IDs, timestamps, relationships, completed-game snapshots, and audit field paths before writing. It refuses to import into a non-empty database unless `--replace` is supplied.

## Validation

Before handoff:

```bash
bash scripts/check-specs.sh
mise exec -- mix format --check-formatted
mise exec -- mix test
```

Browser verification should cover desktop, tablet, and phone viewports for the lobby, setup, dashboard, player sheet, audit, and leaderboard routes.

## Credits

- Original single-player sheet by [Nathan Strutz](https://github.com/nathanstrutz/cashflow-balance-sheet)
- Cashflow is a registered trademark of Robert Kiyosaki & The Rich Dad Company
