defmodule Cashflow.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "games" do
    field :title, :string
    field :status, :string, default: "active"
    field :completed_at, :utc_datetime
    field :winner_player_id, :binary_id
    field :winner_comment, :string
    field :lock_version, :integer, default: 1

    has_many :players, Cashflow.Games.Player
    has_many :audit_events, Cashflow.Games.AuditEvent
    has_many :leaderboard_records, Cashflow.Games.LeaderboardRecord

    timestamps(type: :utc_datetime)
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [:title, :status, :completed_at, :winner_player_id, :winner_comment])
    |> validate_required([:title, :status])
    |> validate_inclusion(:status, ["active", "completed"])
    |> validate_length(:title, min: 1, max: 120)
    |> validate_length(:winner_comment, max: 280)
  end

  def complete_changeset(game, attrs) do
    game
    |> changeset(attrs)
    |> optimistic_lock(:lock_version)
  end
end
