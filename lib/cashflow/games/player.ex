defmodule Cashflow.Games.Player do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cashflow.Sheets

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @colors ~w(blue purple orange red green yellow)

  schema "players" do
    field :name, :string
    field :name_key, :string
    field :color, :string
    field :profession, :string, default: ""
    field :phase, :string, default: "rat_race"
    field :sheet_version, :integer, default: 1
    field :sheet_state, :map
    field :summary, :map, default: %{}
    field :last_saved_at, :utc_datetime
    field :lock_version, :integer, default: 1

    belongs_to :game, Cashflow.Games.Game
    has_many :audit_events, Cashflow.Games.AuditEvent
    has_many :leaderboard_records, Cashflow.Games.LeaderboardRecord

    timestamps(type: :utc_datetime)
  end

  def create_changeset(player, attrs) do
    player
    |> cast(attrs, [
      :game_id,
      :name,
      :name_key,
      :color,
      :profession,
      :phase,
      :sheet_version,
      :sheet_state,
      :summary,
      :last_saved_at
    ])
    |> put_name_key()
    |> validate_required([
      :game_id,
      :name,
      :name_key,
      :color,
      :phase,
      :sheet_version,
      :sheet_state
    ])
    |> validate_length(:name, min: 1, max: 80)
    |> validate_inclusion(:color, @colors)
    |> validate_inclusion(:phase, ["rat_race", "fast_track"])
    |> normalize_sheet()
    |> unique_constraint([:game_id, :name_key], name: :players_game_name_key_idx)
    |> unique_constraint([:game_id, :color], name: :players_game_color_idx)
  end

  def sheet_changeset(player, attrs) do
    player
    |> cast(attrs, [:phase, :sheet_version, :sheet_state, :summary, :last_saved_at])
    |> validate_required([:phase, :sheet_version, :sheet_state])
    |> validate_inclusion(:phase, ["rat_race", "fast_track"])
    |> normalize_sheet()
    |> optimistic_lock(:lock_version)
  end

  defp put_name_key(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        put_change(changeset, :name_key, name |> String.trim() |> String.downcase())
    end
  end

  defp normalize_sheet(changeset) do
    case get_change(changeset, :sheet_state) || get_field(changeset, :sheet_state) do
      nil ->
        changeset

      sheet ->
        case Sheets.normalize(sheet) do
          {:ok, sheet} ->
            changeset
            |> put_change(:sheet_state, sheet)
            |> put_change(:sheet_version, sheet["schema_version"])
            |> put_change(:phase, sheet["phase"])

          {:error, reason} ->
            add_error(changeset, :sheet_state, "is invalid: #{reason}")
        end
    end
  end
end
