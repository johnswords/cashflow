# Rat Race And Fast Track Transitions

| Field | Value |
| --- | --- |
| Status | Target |
| Implementation | `Cashflow.Games` transition functions and changesets |
| Feature Flag | None |
| Last Verified | 2026-05-27 |
| Linear Issue | TBD |
| Depends On | `cashflow-calculations.md`, `versioned-sheet-state.md` |
| Truth Mode | Target |

## Problem

The current app exposes Rat Race/Fast Track as a manual sheet toggle. A full game round needs explicit phase state and guardrails so the host can trust recaps and leaderboard entries.

## Target Behavior

- Players start in `rat_race`.
- The domain exposes `eligible_for_fast_track?/1`.
- Transitioning to fast track records an audit event and stores the summary that justified the transition.
- A player in fast track cannot accidentally edit rat-race-only fields unless the flow is an explicit correction.
- Fast-track win state is recorded before game completion.

## Acceptance

- Attempting to transition before passive income exceeds expenses returns a validation error.
- Transition success writes one persisted sheet update and one audit event in the same transaction.
- Completed games reject phase transitions.
- Recap views show the phase and transition reason for each player.
