#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

required_files=(
  "docs/legacy-app-risk-inventory.md"
  "docs/SPEC.md"
  "docs/specs/game-domain/SPEC.md"
  "docs/specs/game-domain/versioned-sheet-state.md"
  "docs/specs/game-domain/cashflow-calculations.md"
  "docs/specs/game-domain/rat-race-fast-track-transitions.md"
  "docs/specs/game-domain/audit-event-model.md"
  "docs/specs/web/SPEC.md"
  "docs/specs/web/liveview-game-lobby.md"
  "docs/specs/web/new-game-setup.md"
  "docs/specs/web/active-game-dashboard.md"
  "docs/specs/web/player-turn-sheet.md"
  "docs/specs/web/audit-corrections.md"
  "docs/specs/web/end-game-and-recap.md"
  "docs/specs/web/leaderboard.md"
  "docs/specs/web/liveview-session-and-concurrency.md"
  "docs/specs/persistence/SPEC.md"
  "docs/specs/persistence/ecto-schema-and-migrations.md"
  "docs/specs/persistence/sqlite-postgres-compatibility.md"
  "docs/specs/persistence/legacy-data-migration.md"
  "docs/specs/operations/SPEC.md"
  "docs/specs/operations/local-hosting-and-backup.md"
)

missing=0

for file in "${required_files[@]}"; do
  if [[ ! -s "$file" ]]; then
    echo "missing required spec: $file" >&2
    missing=1
  fi
done

exit "$missing"
