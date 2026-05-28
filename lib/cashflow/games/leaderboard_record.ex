defmodule Cashflow.Games.LeaderboardRecord do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "leaderboard_records" do
    field :player_name, :string
    field :game_title, :string
    field :phase, :string
    field :cash_cents, :integer
    field :passive_income_cents, :integer
    field :total_income_cents, :integer
    field :total_expenses_cents, :integer
    field :cashflow_cents, :integer
    field :winner_comment, :string
    field :captured_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :game, Cashflow.Games.Game
    belongs_to :player, Cashflow.Games.Player

    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [
      :game_id,
      :player_id,
      :player_name,
      :game_title,
      :phase,
      :cash_cents,
      :passive_income_cents,
      :total_income_cents,
      :total_expenses_cents,
      :cashflow_cents,
      :winner_comment,
      :captured_at,
      :completed_at
    ])
    |> validate_required([
      :game_id,
      :player_id,
      :player_name,
      :game_title,
      :phase,
      :cash_cents,
      :passive_income_cents,
      :total_income_cents,
      :total_expenses_cents,
      :cashflow_cents,
      :captured_at,
      :completed_at
    ])
  end
end
