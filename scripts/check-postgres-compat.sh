#!/usr/bin/env bash
set -euo pipefail

if [[ "${CASHFLOW_SKIP_POSTGRES_COMPAT:-}" == "1" ]]; then
  echo "Skipping Postgres compatibility gate because CASHFLOW_SKIP_POSTGRES_COMPAT=1."
  exit 0
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required for the Postgres compatibility gate." >&2
  echo "Set CASHFLOW_SKIP_POSTGRES_COMPAT=1 to skip explicitly when no Postgres service is available." >&2
  exit 1
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "psql is required for the Postgres compatibility gate." >&2
  exit 1
fi

schema="cashflow_pg_compat_$(date +%s)_$$"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v compat_schema="$schema" <<'SQL'
BEGIN;

CREATE SCHEMA :"compat_schema";
SET search_path TO :"compat_schema";

CREATE TABLE games (
  id uuid PRIMARY KEY,
  title varchar(255) NOT NULL,
  status varchar(255) NOT NULL DEFAULT 'active',
  completed_at timestamp(0) without time zone,
  winner_player_id uuid,
  winner_comment varchar(255),
  lock_version integer NOT NULL DEFAULT 1,
  inserted_at timestamp(0) without time zone NOT NULL,
  updated_at timestamp(0) without time zone NOT NULL
);

CREATE INDEX games_status_index ON games (status);
CREATE INDEX games_updated_at_index ON games (updated_at);

CREATE TABLE players (
  id uuid PRIMARY KEY,
  game_id uuid NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  name varchar(255) NOT NULL,
  name_key varchar(255) NOT NULL,
  color varchar(255) NOT NULL,
  profession varchar(255) NOT NULL DEFAULT '',
  phase varchar(255) NOT NULL DEFAULT 'rat_race',
  sheet_version integer NOT NULL DEFAULT 1,
  sheet_state jsonb NOT NULL,
  summary jsonb NOT NULL DEFAULT '{}'::jsonb,
  last_saved_at timestamp(0) without time zone,
  lock_version integer NOT NULL DEFAULT 1,
  inserted_at timestamp(0) without time zone NOT NULL,
  updated_at timestamp(0) without time zone NOT NULL
);

CREATE UNIQUE INDEX players_game_name_key_idx ON players (game_id, name_key);
CREATE UNIQUE INDEX players_game_color_idx ON players (game_id, color);
CREATE INDEX players_game_id_index ON players (game_id);

CREATE TABLE audit_events (
  id uuid PRIMARY KEY,
  game_id uuid NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  event_type varchar(255) NOT NULL,
  sheet_schema_version integer NOT NULL,
  baseline_lock_version integer,
  resulting_lock_version integer,
  field_paths_data jsonb NOT NULL,
  changes jsonb NOT NULL DEFAULT '{}'::jsonb,
  before_snapshot jsonb,
  after_snapshot jsonb,
  notes varchar(255),
  origin_event_id uuid,
  inserted_at timestamp(0) without time zone NOT NULL
);

CREATE INDEX audit_events_game_id_inserted_at_index ON audit_events (game_id, inserted_at);
CREATE INDEX audit_events_player_id_inserted_at_index ON audit_events (player_id, inserted_at);
CREATE INDEX audit_events_origin_event_id_index ON audit_events (origin_event_id);

CREATE TABLE leaderboard_records (
  id uuid PRIMARY KEY,
  game_id uuid NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  player_name varchar(255) NOT NULL,
  game_title varchar(255) NOT NULL,
  phase varchar(255) NOT NULL,
  cash_cents integer NOT NULL,
  passive_income_cents integer NOT NULL,
  total_income_cents integer NOT NULL,
  total_expenses_cents integer NOT NULL,
  cashflow_cents integer NOT NULL,
  winner_comment varchar(255),
  captured_at timestamp(0) without time zone NOT NULL,
  completed_at timestamp(0) without time zone NOT NULL,
  inserted_at timestamp(0) without time zone NOT NULL,
  updated_at timestamp(0) without time zone NOT NULL
);

CREATE UNIQUE INDEX leaderboard_game_player_idx ON leaderboard_records (game_id, player_id);
CREATE INDEX leaderboard_records_cashflow_cents_index ON leaderboard_records (cashflow_cents);
CREATE INDEX leaderboard_records_captured_at_index ON leaderboard_records (captured_at);

INSERT INTO games (
  id, title, status, completed_at, winner_player_id, inserted_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Postgres Compatibility',
  'completed',
  '2026-05-27 00:00:00',
  '00000000-0000-0000-0000-000000000101',
  '2026-05-27 00:00:00',
  '2026-05-27 00:00:00'
);

INSERT INTO players (
  id, game_id, name, name_key, color, phase, sheet_state, summary, inserted_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-000000000001',
  'Ada',
  'ada',
  'blue',
  'rat_race',
  '{"schema_version": 1, "phase": "rat_race"}'::jsonb,
  '{"cashflow_cents": 0}'::jsonb,
  '2026-05-27 00:00:00',
  '2026-05-27 00:00:00'
);

INSERT INTO audit_events (
  id, game_id, player_id, event_type, sheet_schema_version, field_paths_data, changes, inserted_at
) VALUES (
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000101',
  'completion',
  1,
  '{"paths":["game.status"]}'::jsonb,
  '{}'::jsonb,
  '2026-05-27 00:00:00'
);

INSERT INTO leaderboard_records (
  id, game_id, player_id, player_name, game_title, phase, cash_cents,
  passive_income_cents, total_income_cents, total_expenses_cents, cashflow_cents,
  captured_at, completed_at, inserted_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000301',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000101',
  'Ada',
  'Postgres Compatibility',
  'rat_race',
  0,
  0,
  0,
  0,
  0,
  '2026-05-27 00:00:00',
  '2026-05-27 00:00:00',
  '2026-05-27 00:00:00',
  '2026-05-27 00:00:00'
);

ROLLBACK;
SQL

echo "Postgres compatibility gate passed for schema DDL, JSON fields, foreign keys, indexes, and snapshot inserts."
