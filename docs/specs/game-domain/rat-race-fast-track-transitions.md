# Rat Race And Fast Track Transitions

| Field | Value |
| --- | --- |
| Status | Partial |
| Implementation | Partial |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `cashflow-calculations.md`, `versioned-sheet-state.md` |
| Truth Mode | Current plus target gaps |

## Current Behavior

- Players start in `rat_race`.
- `Cashflow.Calculations.eligible_for_fast_track?/1` uses strict passive-income greater-than total-expenses logic.
- `Cashflow.Games.transition_player_to_fast_track/3` rejects ineligible players.
- A successful transition saves the Fast Track sheet and records a `phase_transition` audit event in one transaction.
- Completed games reject later phase transitions through the shared active-game guard.

## Problem

The retired app exposed Rat Race/Fast Track as a manual sheet toggle. The Phoenix implementation has explicit phase state and guarded transitions, while richer transition evidence and final win-state enforcement remain target work.

## Target Gaps

- The transition should store the summary that justified the transition in a more explicit audit payload.
- A player in fast track cannot accidentally edit rat-race-only fields unless the flow is an explicit correction.
- Fast-track win state is recorded before game completion.

## Acceptance

- Attempting to transition before passive income exceeds expenses returns a validation error.
- Transition success writes one persisted sheet update and one audit event in the same transaction.
- Completed games reject phase transitions.
- Recap views show the phase and transition reason for each player.
