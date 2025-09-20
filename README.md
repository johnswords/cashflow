# CashFlow Balance Sheet - Multiplayer Edition

A persistent, multi-player digital game sheet for Rich Dad's CashFlow board game with retro Nintendo-style presentation. Track income, expenses, assets, and liabilities across multiple games with automatic calculations and audit history.

Originally forked from https://nathanstrutz.github.io/cashflow-balance-sheet/ - now evolved into a full multiplayer experience backed by SQLite.

---

## 🎮 Features

### Current (v0.5)
- **Single & Multiplayer Modes**: Original single-player sheet plus new persistent multiplayer support
- **Game Management**: Create games with 2-6 players, each with unique color assignments
- **Persistent Storage**: SQLite backend preserves all game states with full audit trail
- **Real-time Calculations**: Automatic computation of passive income, cash flow, and ROI
- **Two Game Modes**: Full support for both "Rat Race" and "Fast Track" phases
- **Backend API**: Koa-based REST service managing games, players, and leaderboards
- **Vuex State Management**: Centralized state with backend synchronization

### In Development
- **Retro Load Screen**: Nintendo-style menu with game selection and leaderboard
- **Game Dashboard**: View all players' financial summaries at a glance
- **Audit Trail**: Complete history of every change with correction tagging
- **Winner Flow**: End game ceremony with leaderboard integration
- **Sound Effects**: SNES/GameCube-era save confirmations and victory fanfare

### Planned
- **Leaderboard**: Top performers ranked by final cash flow
- **Timer Tracking**: Game and turn duration metrics
- **Enhanced Animations**: Screen transitions and celebratory effects

---

## 🚀 Getting Started

### Prerequisites
- Node.js 16+ and npm
- SQLite3

### Installation

```bash
# Clone the repository
git clone https://github.com/johnswords/cashflow.git
cd cashflow

# Install dependencies
npm install

# Set up the database
npm run db:setup

# Start the backend server (port 3001)
npm run backend

# In another terminal, start the Vue dev server (port 8080)
npm run serve
```

Visit http://localhost:8080 to play!

### Single Player Mode
The original single-player experience remains fully functional at the root path with localStorage persistence.

### Multiplayer Mode (Beta)
Access multiplayer features through the API-driven game management system. Currently requires direct API interaction while the UI is being completed.

---

## 🏗️ Architecture

### Frontend (Vue 2 + Vuex)
- **Components**: Modular input components with automatic Vuex binding
- **State Modules**: Separated concerns for income, expenses, assets, liabilities, investments
- **Persistence**: Dual-mode with localStorage (single-player) and API sync (multiplayer)

### Backend (Koa + SQLite)
- **REST API**: Full CRUD for games, players, audit logs, and leaderboards
- **Database**: SQLite with Kysely query builder and migration support
- **Transactions**: ACID-compliant multi-entity updates

### Data Model
```
Games → Players → Sheet States (JSON)
     ↘ Audit Log Entries
     ↘ Leaderboard Records
```

---

## 🎯 Roadmap Progress

- ✅ SQLite schema and migrations
- ✅ Backend API service
- ✅ Vuex multiplayer state management
- ⏳ Retro-themed UI screens (50% complete)
- ⏳ Audit trail interface
- ⏳ Leaderboard view
- ⏳ Sound effects and animations
- 📋 Keyboard/controller navigation
- 📋 1080p shared-screen optimizations

---

## 💻 Development

### Commands

```bash
npm run serve       # Vue dev server with hot reload
npm run backend     # Koa API server
npm run build       # Production build
npm run db:migrate  # Run database migrations
npm run db:seed     # Load sample data (coming soon)
```

### Project Structure

```
src/
├── api/           # API client for backend communication
├── backend/       # Koa server, routes, and DB queries
├── components/    # Vue components (inputs, sheets, modals)
├── stores/        # Vuex modules and plugins
├── utils/         # Shared utilities and helpers
└── App.vue        # Root component with routing logic
```

### Contributing

This is a personal project for family game nights, but suggestions and bug reports are welcome! Please open an issue to discuss any proposed changes.

---

## 🚢 Deployment

### GitHub Pages (Static Single-Player Only)

```bash
git checkout gh-pages
git merge main
# Edit vue.config.js: add publicPath: "/cashflow/"
npm run build
git add dist/*
git commit -m "Deploy to GitHub Pages"
git subtree push --prefix dist origin gh-pages
```

### Full Stack Deployment
Multiplayer mode requires a Node.js host with SQLite support. Deployment guides for popular platforms coming soon.

---

## 📝 License

MIT License - Feel free to use this for your own CashFlow game sessions!

---

## 🙏 Acknowledgments

- Original single-player implementation by [Nathan Strutz](https://github.com/nathanstrutz/cashflow-balance-sheet)
- CashFlow board game by Robert Kiyosaki
- Built for Henry and friends to make game night calculations effortless
