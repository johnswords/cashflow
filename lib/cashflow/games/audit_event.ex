defmodule Cashflow.Games.AuditEvent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cashflow.Sheets

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @event_types ~w(turn correction phase_transition completion)
  @game_paths ~w(game.status game.winner_player_id)

  schema "audit_events" do
    field :event_type, :string
    field :sheet_schema_version, :integer
    field :baseline_lock_version, :integer
    field :resulting_lock_version, :integer
    field :field_paths, {:array, :string}, virtual: true
    field :field_paths_data, :map
    field :changes, :map, default: %{}
    field :before_snapshot, :map
    field :after_snapshot, :map
    field :notes, :string
    field :origin_event_id, :binary_id

    belongs_to :game, Cashflow.Games.Game
    belongs_to :player, Cashflow.Games.Player

    timestamps(updated_at: false, type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :game_id,
      :player_id,
      :event_type,
      :sheet_schema_version,
      :baseline_lock_version,
      :resulting_lock_version,
      :field_paths,
      :field_paths_data,
      :changes,
      :before_snapshot,
      :after_snapshot,
      :notes,
      :origin_event_id
    ])
    |> normalize_field_paths()
    |> validate_field_paths()
    |> validate_required([
      :game_id,
      :player_id,
      :event_type,
      :field_paths_data,
      :sheet_schema_version
    ])
    |> validate_inclusion(:event_type, @event_types)
    |> validate_length(:notes, max: 280)
  end

  defp normalize_field_paths(changeset) do
    field_paths = get_change(changeset, :field_paths)
    data = get_change(changeset, :field_paths_data)

    cond do
      is_list(field_paths) ->
        put_change(changeset, :field_paths_data, %{"paths" => field_paths})

      is_map(data) ->
        changeset

      true ->
        put_change(changeset, :field_paths_data, %{"paths" => []})
    end
  end

  defp validate_field_paths(changeset) do
    validate_change(changeset, :field_paths_data, fn :field_paths_data, data ->
      paths = Map.get(data || %{}, "paths", [])

      invalid_paths =
        paths
        |> List.wrap()
        |> Enum.reject(&valid_field_path?/1)

      case invalid_paths do
        [] -> []
        _ -> [field_paths_data: "contains invalid paths: #{Enum.join(invalid_paths, ", ")}"]
      end
    end)
  end

  defp valid_field_path?(path) when path in @game_paths, do: true
  defp valid_field_path?(path), do: Sheets.valid_path?(path)
end
