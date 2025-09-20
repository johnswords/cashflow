# Cashflow Balance Sheet – Multiplayer Arcade

A retro-inspired control room for Rich Dad's Cashflow board game. Spin up Nintendo-style game sessions, manage 2–6 players, capture every sheet adjustment with an audit trail, and crown winners with persistent leaderboards. The single-player calculator is still here—but now it lives inside a full multiplayer flow backed by SQLite.

---

## ✨ What’s Shipped Now
- **Retro Load Screen & Navigation** – animated New Game / List Games / Leaderboard menu with keyboard support.
- **Game Lifecycle** – create, resume, and complete games with unique IDs, player colors, and persistent state.
- **Per-Player Sheets** – reuse the original Rat Race & Fast Track layouts with save/cancel controls and confirmation diffs.
- **Audit Trail** – automatic logging of every change, inline diff preview, correction tagging, and rewind-to-edit workflow.
- **Recent Change Feed** – each player card surfaces the three latest updates with friendly field labels.
- **Winner Flow** – end-game modal captures winner/comment plus a final stats snapshot and writes to the leaderboard.
- **SNES/GameCube Audio** – quick chimes on save and a short victory fanfare, with a global mute toggle.
- **SQLite Persistence** – Koa + better-sqlite3 backend manages games, players, audits, and leaderboard snapshots.

## 🚧 In Progress / Up Next
- **Leaderboard polish** – richer layout, filters, and navigation back to completed games.
- **Responsive 1080p view** – shared-screen spacing and typography tuning.
- **Timers** – game duration plus per-turn timers for future analytics.
- **Animations & FX** – transitions, CRT overlays, and more in-game flair.

---

## 🧰 Prerequisites
- Node.js 18+
- npm 10+
- SQLite (included via `better-sqlite3`, no separate install required)

---

## ⚙️ Local Development

```bash
# Install dependencies
npm install

# Run database migrations (creates ./data/cashflow.sqlite)
npm run backend:migrate

# Start the backend API on http://localhost:4000
npm run backend:dev

# In a second terminal, start the Vue dev server on http://localhost:8080
npm run serve
```

The Vue dev server proxies `/api/*` requests to the backend (see `vue.config.js`). Game data lives in the `data/` directory, which is gitignored.

### Useful Commands
| Command | Description |
| --- | --- |
| `npm run backend:migrate` | Apply pending SQLite migrations |
| `npm run backend:dev` | Run Koa API server with nodemon |
| `npm run backend:seed` | Placeholder for future seed data |
| `npm run serve` | Vue dev server with hot reload |
| `npm run build` | Production build (frontend only) |

---

## 🏛️ Architecture

### Frontend (Vue 2 + Vuex)
- `src/App.vue` swaps between retro views (`LoadScreen`, `NewGameSetup`, `GameList`, `GameScreen`, `PlayerSheetView`, `LeaderboardView`).
- Vuex (`src/store.js`) owns the multiplayer state machine, audit pagination, modals, and sheet normalization helpers.
- Domain stores in `src/stores/` keep the original financial module structure (income, expenses, etc.).
- API client lives in `src/api/client.js` and communicates with the backend REST endpoints.

### Backend (Koa + Kysely + better-sqlite3)
- Entry point: `src/backend/server.js`.
- Routes: `games`, `leaderboard`, `health` under `/api/*`.
- Migrations: `src/backend/db/migrations` (run via `npm run backend:migrate`).
- Data directory: `data/cashflow.sqlite` (auto-created, WAL mode enabled).

### Key Tables
| Table | Purpose |
| --- | --- |
| `games` | Game metadata, status, timestamps, winner info |
| `players` | Per-player sheet state (JSON blob), color, name |
| `audit_log_entries` | Change history with before/after snapshots |
| `leaderboard_records` | Final cashflow snapshots for completed games |

---

## 📂 Project Layout
```
src/
├── api/            # Frontend REST client
├── backend/        # Koa server, migrations, routes
├── components/
│   ├── app/        # Load screen, dashboards, modals, toggles
│   ├── misc/ …     # Reusable inputs
│   └── ratrace/…   # Original sheet components
├── stores/         # Vuex modules + plugins
├── utils/          # Helpers (diffing, audio, cashflow math)
├── App.vue         # Retro view router
└── main.js         # Bootstraps Vue app
```

---

## 🧪 Testing
Automated tests are still TODO. For now:
- Run `npm run backend:migrate` before manual testing to ensure schema sync.
- Exercise the main flows:
  1. Create a new game (2–6 players) and verify unique colors enforced.
  2. Adjust a player sheet, confirm diff modal + audit log entry.
  3. Trigger a correction from the audit modal and confirm it logs with `entryType = correction`.
  4. Finish a game, confirm leaderboard refresh + fanfare.

Document manual results in PRs until Jest/Vue Test Utils are in place.

---

## 🚀 Deployment Notes
- **Frontend-only (legacy)**: You can still deploy the static build, but multiplayer features require the backend.
- **Full stack**: Host the Node backend (4000) and serve the Vue build behind the same domain or a reverse proxy. Ensure the `data/` directory is writable.
- Containerization scripts are on the roadmap once the schema stabilizes.

---

## 🤝 Contributing
This project powers family & friends game nights—bug reports and ideas welcome. Open an issue with steps to reproduce or a proposal before sending large PRs. Follow the coding style and commit guidance in `AGENTS.md`.

---

## 🙏 Credits
- Original single-player sheet by [Nathan Strutz](https://github.com/nathanstrutz/cashflow-balance-sheet)
- Cashflow is a registered trademark of Robert Kiyosaki & The Rich Dad Company
- Multiplayer arcade edition crafted for Henry, Ashley, and the Cashflow crew
