# AGENTS.md

Read README.md for project overview. This file contains coding style and commit message guidelines.

## Project Overview

A Vue 2 web application that provides an interactive digital game sheet for the CashFlow board game. It helps players track income, expenses, assets, and liabilities without manual calculations, supporting both "Rat Race" and "Fast Track" game modes.

## Development Commands

```bash
# Install dependencies
npm install

# Run development server with hot reload (port 8080)
npm run serve

# Build for production
npm run build

# Deploy to GitHub Pages (from gh-pages branch)
git checkout gh-pages
git merge vue
# Edit vue.config.js and add: publicPath: "/cashflow-balance-sheet"
npm run build
git add dist/*
git commit -m "Building"
git subtree push --prefix dist origin gh-pages
```

## Architecture Overview

### Core Application Structure

**Vue 2 + Vuex Architecture**: The app uses a centralized Vuex store with modular state management. All financial data flows through the store with computed getters for derived values (passive income, cash flow, etc.).

**Two-Mode System**:
- **Rat Race**: Main gameplay sheet with income statement and balance sheet
- **Fast Track**: Simplified interface for when players escape the rat race (winning condition)

### State Management Pattern

The Vuex store (`src/store.js`) orchestrates several modules:
- `income`: Salary and passive income sources
- `expenses`: All expense categories including dynamic child expenses
- `liabilities`: Debts and loans
- `assets`: Current asset values
- `investments`: Real estate, businesses, and stocks with modal management
- `fasttrack`: Fast track mode specific state
- `meta`: Player metadata (name, profession, auditor)

**Key Computed Properties**: The store centralizes complex calculations:
- `passiveIncome`: Aggregates all non-salary income
- `totalIncome`: Salary + passive income
- `totalExpenses`: All expenses including dynamic bank loans
- `cashFlow`: The critical metric (totalIncome - totalExpenses)

### Component Hierarchy

**Input Components** (`src/components/misc/`):
- Custom input components (`DollarFormatInput`, `StateConnectedInput`) that auto-bind to Vuex state
- Specialized inputs for business names, property names, and stock symbols
- All inputs use two-way binding with Vuex mutations

**Modal System**: Investment editing uses a centralized modal system managed through Vuex state (`investments.modal`). Modals for real estate, businesses, and stocks share state management patterns.

### Persistence & Plugins

**LocalStorage Plugin** (`src/stores/plugins/localstorage.js`): Auto-saves game state to browser storage on every mutation, with automatic restoration on page load.

**Reset State Plugin** (`src/stores/plugins/resetstate.js`): Provides clean state reset functionality while preserving the localStorage plugin.

### Styling Architecture

- Global SCSS variables loaded via `palette.scss` (auto-imported in all components)
- Print-optimized styles that hide controls and adjust formatting
- Component-scoped styles with deep selectors for child component styling

## Key Technical Patterns

### Investment Management
Each investment type (real estate, business, stock) follows a consistent pattern:
1. Array storage with pre-allocated slots
2. Modal-based editing with index tracking
3. Automatic calculation of derived values (total cost, ROI, etc.)
4. Dynamic row addition with minimum slot requirements

### Reactive Calculations
All totals and summaries use Vuex getters that automatically recalculate when underlying state changes. This ensures consistency across the entire sheet without manual updates.

### State Mutation Pattern
All state changes go through explicit Vuex mutations with descriptive names following the pattern: `change{Module}{Property}` (e.g., `changeStockShares`, `changeRealEstateName`).

## Important Considerations

- Vue 2 (not Vue 3) - uses Options API, not Composition API
- No TypeScript - pure JavaScript with Vue single-file components
- No testing framework configured - manual testing only
- No linting configured beyond Prettier formatting rules
- Browser localStorage is the only persistence mechanism
- The `gh-pages` branch requires manual publicPath configuration for deployment
