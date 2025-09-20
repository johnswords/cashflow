# Engineering Playbook

## Project Overview
- Vue 2 application (`src/main.js`, `src/App.vue`) renders retro-inspired flows for Cashflow game management.
- Vuex (`src/store.js`) orchestrates multiplayer state: view routing, sheet normalization, audit logging, modals, audio prefs.
- Backend lives in `src/backend/` (Koa + better-sqlite3 via Kysely) and exposes `/api/*` routes for games, players, audits, leaderboard.
- SQLite database stored at `data/cashflow.sqlite` (gitignored, WAL mode). Use migration scripts to evolve schema.

## Development Workflow
| Task | Command |
| --- | --- |
| Install deps | `npm install` |
| Run migrations | `npm run backend:migrate` |
| Start API (4000) | `npm run backend:dev` |
| Start frontend (8080) | `npm run serve` |
| Production build | `npm run build` |
| Seed data | `npm run backend:seed` (stub – extend when needed) |

Always keep backend + frontend running together for multiplayer flows. Proxy is configured in `vue.config.js`.

## Coding Standards
- Use Vue SFC order `<template>`, `<script>`, `<style lang="scss">`. Two-space indent.
- Prefer composable helpers in `src/utils/` (diffing, cashflow math, audio).
- Vuex mutations/actions should stay pure and commit-friendly—avoid direct async inside mutations.
- Normalize sheet state before saving (see `buildSheetState`/`applySheetStateToModules`).
- Audio helpers should route through `playSound`/`setAudioEnabled` to respect user preferences.

## Backend Guidelines
- Add migrations in `src/backend/db/migrations` (timestamp-named JS files using Kysely schema builder).
- Wrap multi-entity writes in transactions (`db.transaction().execute`).
- Keep route modules small: input validation with Zod (`src/backend/validators`), serialization helpers for DB rows.
- Return ISO timestamps; frontend expects `createdAt`, `updatedAt`, etc.

## UI / UX Notes
- Retro aesthetic: `Press Start 2P` font, neon gradients, 80s palette.
- Audio toggle (`AudioToggle.vue`) should be visible on major screens.
- Confirmation modals must surface diff summaries before committing changes.
- Audit modal (`AuditLogModal.vue`) is the single source of truth for history; corrections bounce users into sheet editor with prefilled state.
- End game modal captures winner + comment and shows summary stats before committing.

## Testing & QA
- Automated tests pending; document manual verification in PR descriptions.
- Before submitting PRs: run `npm run backend:migrate` (ensures schema), then `npm run build` (catches compilation issues despite Sass deprecation warnings).
- Check audit log after major flows (create → save → correction → end game) to ensure IDs/timestamps look sane.

## Git & PR Hygiene
- Use imperative commit messages (`feat: add audit modal`).
- Group backend/ frontend changes logically; avoid large mixed commits if possible.
- Include screenshots/GIFs for UI updates (retro theme changes matter); list manual test cases executed.

## State & Data Flow Reference
```
Vuex root state
├─ currentView (load-screen, new-game-setup, game-list, game-screen, player-sheet, leaderboard)
├─ games[]           # fetched summaries
├─ activeGame        # detailed game with players[]
├─ activePlayerId    # selected player for sheet view
├─ auditEntries[]    # paginated history for current game
├─ leaderboard[]
├─ endGameForm       # winner/comment draft
├─ ui                # modal visibility flags
└─ preferences.audioEnabled
```
Persisted sheet structure mirrors legacy modules (income/expenses/etc.) and is stored as JSON blobs per player.

## Outstanding Work (See `TODO.md` for granular list)
- Leaderboard polish, timers, responsive scaling, richer audit diff labels for nested assets.

Stay consistent, keep the retro vibe alive, and document gameplay impact as we ship new features.
