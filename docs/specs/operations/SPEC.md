# Operations Surface Spec

Last Verified: 2026-05-27
Status: Partial
Truth Mode: Current implementation plus target gaps

## Boundary

The operations surface owns local developer setup, family-night run commands, health checks, seed/demo data, backup/restore, and deployment assumptions.

## Current Invariants

- A fresh checkout can install dependencies, create the database, migrate, seed optional demo data, and start the app with documented commands.
- Local runtime defaults to SQLite in a repo-local or user-configured data directory.
- Backup export is available at `/backup.json`.
- Backup restore/import is available through `mix cashflow.backup.restore`.
- Demo data can be regenerated without touching production/family data.
- No-auth local mode is explicit in README and runtime configuration. Any future hosted auth model requires a new spec.

## Target Gaps

- Runtime config does not yet support Postgres through `DATABASE_URL`; hosted deployment needs the compatibility gate first.
- A simple health endpoint is not yet present.
- Backup freshness is not surfaced in the UI.

## Feature Specs

- `local-hosting-and-backup.md`

## Acceptance

- A non-developer host can follow README commands to start a local game.
- Release/startup runs migrations or clearly documents the migration command.
- Backup export and restore are validated before handoff.
