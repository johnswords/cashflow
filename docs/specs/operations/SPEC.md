# Operations Surface Spec

Last Verified: 2026-05-27
Status: Target specification
Truth Mode: Target

## Boundary

The operations surface owns local developer setup, family-night run commands, health checks, seed/demo data, backup/restore, and deployment assumptions.

## Target Invariants

- A fresh checkout can install dependencies, create the database, migrate, seed optional demo data, and start the app with documented commands.
- Local runtime defaults to SQLite in a repo-local or user-configured data directory.
- Runtime config supports Postgres through `DATABASE_URL` without changing application code.
- The app exposes a simple health endpoint or LiveDashboard-compatible health check.
- Backups are easy enough to run before a game night.
- Demo data can be regenerated without touching production/family data.
- No-auth local mode is explicit in README and runtime configuration. Any future hosted auth model requires a new spec.

## Feature Specs

- `local-hosting-and-backup.md`

## Acceptance

- A non-developer host can follow README commands to start a local game.
- Release/startup runs migrations or clearly documents the migration command.
- Backup and restore are validated on a temporary database.
