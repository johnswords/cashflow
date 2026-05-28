defmodule Cashflow.Repo.Migrations.CreateCashflowSchema do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :status, :string, null: false, default: "active"
      add :completed_at, :utc_datetime
      add :winner_player_id, :binary_id
      add :winner_comment, :string
      add :lock_version, :integer, null: false, default: 1

      timestamps(type: :utc_datetime)
    end

    create index(:games, [:status])
    create index(:games, [:updated_at])

    create table(:players, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :name_key, :string, null: false
      add :color, :string, null: false
      add :profession, :string, null: false, default: ""
      add :phase, :string, null: false, default: "rat_race"
      add :sheet_version, :integer, null: false, default: 1
      add :sheet_state, :map, null: false
      add :summary, :map, null: false, default: %{}
      add :last_saved_at, :utc_datetime
      add :lock_version, :integer, null: false, default: 1

      timestamps(type: :utc_datetime)
    end

    create unique_index(:players, [:game_id, :name_key], name: :players_game_name_key_idx)
    create unique_index(:players, [:game_id, :color], name: :players_game_color_idx)
    create index(:players, [:game_id])

    create table(:audit_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all), null: false
      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :sheet_schema_version, :integer, null: false
      add :baseline_lock_version, :integer
      add :resulting_lock_version, :integer
      add :field_paths_data, :map, null: false
      add :changes, :map, null: false, default: %{}
      add :before_snapshot, :map
      add :after_snapshot, :map
      add :notes, :string
      add :origin_event_id, :binary_id

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create index(:audit_events, [:game_id, :inserted_at])
    create index(:audit_events, [:player_id, :inserted_at])
    create index(:audit_events, [:origin_event_id])

    create table(:leaderboard_records, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all), null: false
      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all), null: false
      add :player_name, :string, null: false
      add :game_title, :string, null: false
      add :phase, :string, null: false
      add :cash_cents, :integer, null: false
      add :passive_income_cents, :integer, null: false
      add :total_income_cents, :integer, null: false
      add :total_expenses_cents, :integer, null: false
      add :cashflow_cents, :integer, null: false
      add :winner_comment, :string
      add :captured_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:leaderboard_records, [:game_id, :player_id],
             name: :leaderboard_game_player_idx
           )

    create index(:leaderboard_records, [:cashflow_cents])
    create index(:leaderboard_records, [:captured_at])
  end
end
