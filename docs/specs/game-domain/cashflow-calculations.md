# Cashflow Calculations

| Field | Value |
| --- | --- |
| Status | Current |
| Implementation | Complete |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `versioned-sheet-state.md` |
| Truth Mode | Current |

## Problem

The retired Vue/Koa prototype duplicated cashflow math in frontend and backend JavaScript and used inconsistent bank-loan behavior. Money parsing also stripped signs and decimals in shared UI input code.

## Current Behavior

- Calculations live in one Elixir module and are called by contexts and LiveViews.
- Money parsing accepts signed values where the sheet allows them.
- The persisted money representation is signed integer cents. Calculations stay in integer space and floats are forbidden.
- Display formatting is separate from domain parsing.
- Calculations return summary maps for dashboard, audit, completion, and leaderboard use.

## Required Calculations

- Passive income: interest, secondary interest/dividends, real estate income, and business income.
- Total income: salary plus passive income.
- Child expenses: number of children multiplied by per-child expense.
- Bank-loan payment: one consistent rule, documented and tested.
- Total expenses: all recurring expenses plus child expenses and bank-loan payment.
- Cashflow: total income minus total expenses.
- Escape check: passive income greater than total expenses.
- Completion snapshot: cash, passive income, total income, total expenses, cashflow, phase, winner fields.

## Acceptance

- Tests cover representative rat-race, fast-track eligibility, bank-loan payment, child-expense, and large-integer rounding behavior.
- Calculation results are identical whether called from a LiveView event, seed script, import, or completion flow.
- No user-entered money value is coerced through JavaScript-only parsing.
