# SQLite Service Plan

## Overview
Build a lightweight Node service that wraps a local SQLite database and exposes a minimal REST API for the Vue app. The service lives inside this repo for now, runs alongside the Vue dev server, and persists data on disk so multiple games/sessions survive reloads.

## Tech Stack
- Node 18 runtime shared with the existing tooling
- Koa 2 + koa-router for a small REST surface (swap-able later)
- better-sqlite3 for synchronous, file-based SQLite access (fast for single-process usage)
- Kysely for typed query builder + schema migrations (alternatively drizzle-kit; choose one)
- Zod for request/response validation
- Nodemon for local dev auto-restart

## Project Layout
```
src/
  backend/
    server.js            # entry point
    db/
      connection.js
      migrations/
        0001_init.sql
      seeds/
        demo-data.js (optional)
    routes/
      games.js
      players.js
      audit.js
    validators/
      games.js
      common.js
```

Package scripts added to root `package.json`:
- `npm run backend:dev` – nodemon `src/backend/server.js`
- `npm run backend:migrate` – runs Kysely migration runner
- `npm run backend:seed` – optional seed command for demo data
- `npm run backend:types` – generate Kysely typings (if using TypeScript wrapper)

## Database Schema
```
Game
----
id TEXT PRIMARY KEY
Title TEXT NOT NULL
Status TEXT CHECK (status IN ('active','completed')) NOT NULL DEFAULT 'active'
CreatedAt TEXT NOT NULL
UpdatedAt TEXT NOT NULL
CompletedAt TEXT NULL
WinnerPlayerId TEXT NULL REFERENCES Player(id)
WinnerComment TEXT NULL

Player
------
id TEXT PRIMARY KEY
GameId TEXT NOT NULL REFERENCES Game(id) ON DELETE CASCADE
Name TEXT NOT NULL
Color TEXT NOT NULL CHECK (color IN ('blue','purple','orange','red','green','yellow'))
SheetState TEXT NOT NULL   -- JSON string
LastModifiedAt TEXT NOT NULL

AuditLogEntry
-------------
id TEXT PRIMARY KEY
GameId TEXT NOT NULL REFERENCES Game(id) ON DELETE CASCADE
PlayerId TEXT NOT NULL REFERENCES Player(id) ON DELETE CASCADE
Timestamp TEXT NOT NULL
EntryType TEXT CHECK (entryType IN ('turn','correction')) NOT NULL
FieldPaths TEXT NOT NULL -- JSON array of field identifiers
BeforeSnapshot TEXT NOT NULL -- JSON diff snapshot
AfterSnapshot TEXT NOT NULL -- JSON diff snapshot
Notes TEXT NULL
OriginEntryId TEXT NULL REFERENCES AuditLogEntry(id)

LeaderboardRecord
-----------------
id TEXT PRIMARY KEY
GameId TEXT NOT NULL REFERENCES Game(id) ON DELETE CASCADE
PlayerId TEXT NOT NULL REFERENCES Player(id) ON DELETE CASCADE
CashflowValue REAL NOT NULL
CapturedAt TEXT NOT NULL
WinnerComment TEXT NULL
```

All timestamps stored as ISO 8601 strings (UTC). JSON fields validated on save.

## REST API (Draft)
- `GET /health` → `{ ok: true }`
- `GET /games` → list summary (with optional status filter)
- `POST /games` → create game with players
- `GET /games/:id` → full game payload including players (but not audit entries)
- `PATCH /games/:id` → update metadata (title, winner, status)
- `POST /games/:id/end` → mark completed, capture snapshot & leaderboard entries
- `GET /games/:id/audit` → paginated audit entries
- `POST /games/:id/audit` → append entry (used by sheet saves & corrections)
- `GET /games/:id/players/:playerId` → player detail
- `PATCH /games/:id/players/:playerId` → update sheet state (transaction w/ audit)
- `GET /leaderboard` → top N results with filters (e.g., `?limit=20&since=2024-01-01`)

Front-end will rely primarily on `GET /games`, `GET /games/:id`, `PATCH player`, `POST audit`, `POST /games/:id/end`, and `GET /leaderboard`.

## Transactions & Workflows
1. **Create Game**: begin transaction → insert game, insert players, commit.
2. **Save Player Sheet**: begin transaction → update player sheet state + lastModifiedAt → insert audit entry → update game.updatedAt → commit.
3. **Correction**: same as save but with `entry_type = 'correction'` and `origin_entry_id` linking back.
4. **End Game**: begin transaction → update game status/completion info → compute leaderboard records (cashflow via sheetState → derived) → insert leaderboard rows → commit.

## Validation & Error Handling
- Use Zod schemas in validators for request payloads; return 400 with details on failure.
- Wrap DB errors; return 500 with sanitized message.
- Enforce color uniqueness at request level before insert.

## Dev Workflow
- Local .sqlite file stored under `data/cashflow.sqlite` (gitignored).
- `npm run backend:migrate` auto-creates DB if missing.
- Vue dev server proxies `/api/*` to backend (configure in `vue.config.js`).
- Provide seed script to bootstrap a demo game for manual testing.

## Next Steps
1. Add backend dependencies + scripts in `package.json`.
2. Implement migration runner and initial schema.
3. Build Koa server with routes + controllers (start with `GET /health`).
4. Wire Vue dev proxy and create basic API client utilities.

