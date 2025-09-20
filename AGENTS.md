# Repository Guidelines

## Project Structure & Module Organization
Application code lives in `src`, with `main.js` bootstrapping Vue 2 and `App.vue` composing the layout shell. Feature views and shared atoms sit under `src/components`, organized by domain folders such as `fasttrack/` and `ratrace/`. Global state is centralized in `src/store.js`, which wires the modular files under `src/stores/` and the plugin helpers in `src/stores/plugins/`. Static assets and brand imagery belong in `public/` for root-served files or `src/images/` for webpack-managed imports.

## Build, Test, and Development Commands
- `npm install` — install Vue CLI 4 dependencies before first run.
- `npm run serve` — launch the local dev server with hot module reload; default port 8080.
- `npm run build` — produce the minified production bundle in `dist/`.
Run commands from the repository root. Prefer Node 18 LTS for CLI parity.

## Coding Style & Naming Conventions
Use Vue single-file components with the `<script>`, `<template>`, `<style lang="scss">` order. Keep indentation at two spaces and favor descriptive PascalCase for component files (`FastTrack.vue`) and camelCase for stores (`fasttrack.js`). Prettier is configured with `printWidth: 140`; run your editor integration or `npx prettier --write "src/**/*.{js,vue,scss}"` before committing. SCSS variables and palettes belong in `src/palette.scss`; import shared styles rather than redefining constants.

## Testing Guidelines
Automated tests are not yet configured. When introducing coverage, add Vue Test Utils + Jest via `@vue/cli-plugin-unit-jest`, place specs in `tests/unit/`, and mirror the component filename pattern (`FastTrack.spec.js`). Until the suite exists, document manual verification steps in pull requests, especially for financial calculations and responsive layout modes.

## Commit & Pull Request Guidelines
Existing history favors short, imperative commit subjects (e.g., `Fix mobile table layout`). Follow that style and group related changes together. Pull requests should include: a concise summary, linked Linear/GitHub issue (if available), screenshots or screen recordings for UI updates, and explicit test notes (`Tested: npm run serve on macOS Sonoma, Chrome 128`). Request review once linting, builds, and manual checks pass.

## State & Data Flow Notes
Vuex modules in `src/stores/` encapsulate domain data (income, assets, liabilities). Use the existing plugin pattern for persistence—extend `src/stores/plugins/localstorage.js` rather than introducing ad hoc storage logic. Derivations that feed Fast Track dashboards should stay in getters to keep components presentation-focused.
