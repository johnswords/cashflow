defmodule Mix.Tasks.Cashflow.Backup.Restore do
  @moduledoc """
  Restores a Cashflow JSON backup into the configured local database.

      mix cashflow.backup.restore path/to/backup.json
      mix cashflow.backup.restore path/to/backup.json --replace

  The task refuses to import into a non-empty database unless `--replace` is
  supplied. Replacement deletes existing game data inside the same transaction
  that imports the validated backup.
  """

  use Mix.Task

  alias Cashflow.Games
  alias Cashflow.Games.{AuditEvent, Game, LeaderboardRecord, Player}
  alias Cashflow.{Repo, Sheets}

  @shortdoc "Restore a Cashflow backup JSON export"
  @requirements ["app.start"]

  @switches [replace: :boolean]
  @valid_statuses ~w(active completed)
  @valid_event_types ~w(turn correction phase_transition completion)
  @valid_phases ~w(rat_race fast_track)

  @impl Mix.Task
  def run(args) do
    case OptionParser.parse(args, strict: @switches) do
      {opts, [path], []} ->
        path
        |> restore(Keyword.get(opts, :replace, false))
        |> report()

      {_opts, _args, invalid} when invalid != [] ->
        Mix.raise("Unknown option(s): #{inspect(invalid)}")

      _ ->
        Mix.raise("Usage: mix cashflow.backup.restore path/to/backup.json [--replace]")
    end
  end

  defp restore(path, replace?) do
    with {:ok, raw} <- File.read(path),
         {:ok, decoded} <- Jason.decode(raw),
         {:ok, prepared} <- prepare_backup(decoded),
         :ok <- ensure_import_target_empty_or_replace(replace?) do
      import_backup(prepared, replace?)
    else
      {:error, %Jason.DecodeError{} = error} ->
        {:error, "Invalid JSON: #{Exception.message(error)}"}

      {:error, :enoent} ->
        {:error, "Backup file not found: #{path}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp report({:ok, counts}) do
    Mix.shell().info("""
    Restored Cashflow backup:
      games: #{counts.games}
      players: #{counts.players}
      audit_events: #{counts.audit_events}
      leaderboard_records: #{counts.leaderboard_records}
    """)
  end

  defp report({:error, reason}), do: Mix.raise(to_string(reason))

  defp prepare_backup(%{} = backup) do
    with :ok <- validate_schema_version(backup),
         {:ok, games} <- prepare_collection(backup, "games", &prepare_game/1),
         {:ok, audits} <- prepare_collection(backup, "audit_events", &prepare_audit_event/1),
         {:ok, players} <- prepare_collection(backup, "players", &prepare_player(&1, audits)),
         {:ok, leaderboard_records} <-
           prepare_collection(backup, "leaderboard_records", &prepare_leaderboard_record/1),
         :ok <- validate_relationships(games, players, audits, leaderboard_records) do
      {:ok,
       %{
         games: games,
         players: players,
         audit_events: audits,
         leaderboard_records: leaderboard_records
       }}
    end
  end

  defp prepare_backup(_), do: {:error, "Backup must be a JSON object"}

  defp validate_schema_version(%{"schema_version" => version}) do
    if version == Sheets.schema_version() do
      :ok
    else
      {:error,
       "Unsupported backup schema_version #{inspect(version)}; expected #{Sheets.schema_version()}"}
    end
  end

  defp validate_schema_version(_), do: {:error, "Backup is missing schema_version"}

  defp prepare_collection(backup, key, prepare_fun) do
    case Map.fetch(backup, key) do
      {:ok, values} when is_list(values) ->
        values
        |> Enum.with_index()
        |> Enum.reduce_while({:ok, []}, fn {value, index}, {:ok, rows} ->
          case prepare_fun.(value) do
            {:ok, row} -> {:cont, {:ok, [row | rows]}}
            {:error, reason} -> {:halt, {:error, "#{key}[#{index}]: #{reason}"}}
          end
        end)
        |> then(fn
          {:ok, rows} -> {:ok, Enum.reverse(rows)}
          error -> error
        end)

      {:ok, _} ->
        {:error, "#{key} must be a list"}

      :error ->
        {:error, "Backup is missing #{key}"}
    end
  end

  defp prepare_game(%{} = game) do
    with {:ok, id} <- require_uuid(game, "id"),
         {:ok, title} <- require_string(game, "title"),
         {:ok, status} <- require_inclusion(game, "status", @valid_statuses),
         {:ok, winner_player_id} <- optional_uuid(game, "winner_player_id"),
         {:ok, completed_at} <- optional_datetime(game, "completed_at"),
         {:ok, inserted_at} <- require_datetime(game, "inserted_at"),
         {:ok, updated_at} <- require_datetime(game, "updated_at") do
      {:ok,
       %{
         id: id,
         title: String.trim(title),
         status: status,
         completed_at: completed_at,
         winner_player_id: winner_player_id,
         winner_comment: Map.get(game, "winner_comment"),
         lock_version:
           integer_or_default(Map.get(game, "lock_version"), game_lock_version(status)),
         inserted_at: inserted_at,
         updated_at: updated_at
       }}
    end
  end

  defp prepare_game(_), do: {:error, "game must be an object"}

  defp prepare_player(%{} = player, audit_events) do
    with {:ok, id} <- require_uuid(player, "id"),
         {:ok, game_id} <- require_uuid(player, "game_id"),
         {:ok, name} <- require_string(player, "name"),
         {:ok, color} <- require_string(player, "color"),
         {:ok, phase} <- require_inclusion(player, "phase", @valid_phases),
         {:ok, sheet_state} <- require_sheet(player),
         {:ok, last_saved_at} <- optional_datetime(player, "last_saved_at"),
         {:ok, inserted_at} <- require_datetime(player, "inserted_at"),
         {:ok, updated_at} <- require_datetime(player, "updated_at") do
      lock_version = player_lock_version(player, audit_events)

      {:ok,
       %{
         id: id,
         game_id: game_id,
         name: String.trim(name),
         name_key: name |> String.trim() |> String.downcase(),
         color: color,
         profession: Map.get(player, "profession") || "",
         phase: phase,
         sheet_version: sheet_state["schema_version"],
         sheet_state: sheet_state,
         summary: summary_or_default(player, sheet_state),
         last_saved_at: last_saved_at,
         lock_version: lock_version,
         inserted_at: inserted_at,
         updated_at: updated_at
       }}
    end
  end

  defp prepare_player(_, _audit_events), do: {:error, "player must be an object"}

  defp prepare_audit_event(%{} = event) do
    with {:ok, id} <- require_uuid(event, "id"),
         {:ok, game_id} <- require_uuid(event, "game_id"),
         {:ok, player_id} <- require_uuid(event, "player_id"),
         {:ok, event_type} <- require_inclusion(event, "event_type", @valid_event_types),
         {:ok, sheet_schema_version} <- require_integer(event, "sheet_schema_version"),
         {:ok, origin_event_id} <- optional_uuid(event, "origin_event_id"),
         {:ok, inserted_at} <- require_datetime(event, "inserted_at"),
         {:ok, field_paths} <- field_paths(event) do
      {:ok,
       %{
         id: id,
         game_id: game_id,
         player_id: player_id,
         event_type: event_type,
         sheet_schema_version: sheet_schema_version,
         baseline_lock_version: optional_integer(event, "baseline_lock_version"),
         resulting_lock_version: optional_integer(event, "resulting_lock_version"),
         field_paths_data: %{"paths" => field_paths},
         changes: map_or_default(Map.get(event, "changes"), %{}),
         before_snapshot: map_or_nil(Map.get(event, "before_snapshot")),
         after_snapshot: map_or_nil(Map.get(event, "after_snapshot")),
         notes: Map.get(event, "notes"),
         origin_event_id: origin_event_id,
         inserted_at: inserted_at
       }}
    end
  end

  defp prepare_audit_event(_), do: {:error, "audit event must be an object"}

  defp prepare_leaderboard_record(%{} = record) do
    with {:ok, id} <- require_uuid(record, "id"),
         {:ok, game_id} <- require_uuid(record, "game_id"),
         {:ok, player_id} <- require_uuid(record, "player_id"),
         {:ok, game_title} <- require_string(record, "game_title"),
         {:ok, player_name} <- require_string(record, "player_name"),
         {:ok, phase} <- require_inclusion(record, "phase", @valid_phases),
         {:ok, completed_at} <- require_datetime(record, "completed_at"),
         {:ok, inserted_at} <- require_datetime(record, "inserted_at"),
         {:ok, captured_at} <- captured_at(record, completed_at) do
      {:ok,
       %{
         id: id,
         game_id: game_id,
         player_id: player_id,
         player_name: player_name,
         game_title: game_title,
         phase: phase,
         cash_cents: integer_or_default(Map.get(record, "cash_cents"), 0),
         passive_income_cents: integer_or_default(Map.get(record, "passive_income_cents"), 0),
         total_income_cents: integer_or_default(Map.get(record, "total_income_cents"), 0),
         total_expenses_cents: integer_or_default(Map.get(record, "total_expenses_cents"), 0),
         cashflow_cents: integer_or_default(Map.get(record, "cashflow_cents"), 0),
         winner_comment: Map.get(record, "winner_comment"),
         captured_at: captured_at,
         completed_at: completed_at,
         inserted_at: inserted_at,
         updated_at: updated_at(record, inserted_at)
       }}
    end
  end

  defp prepare_leaderboard_record(_), do: {:error, "leaderboard record must be an object"}

  defp validate_relationships(games, players, audit_events, leaderboard_records) do
    with :ok <- ensure_unique("game ids", Enum.map(games, & &1.id)),
         :ok <- ensure_unique("player ids", Enum.map(players, & &1.id)),
         :ok <- ensure_unique("audit event ids", Enum.map(audit_events, & &1.id)),
         :ok <- ensure_unique("leaderboard record ids", Enum.map(leaderboard_records, & &1.id)),
         :ok <- ensure_players_reference_games(games, players),
         :ok <- ensure_audit_events_reference_rows(players, audit_events),
         :ok <- ensure_leaderboard_references_completed_games(games, players, leaderboard_records),
         :ok <- ensure_completed_games_have_snapshots(games, players, leaderboard_records) do
      :ok
    end
  end

  defp ensure_unique(label, ids) do
    if Enum.uniq(ids) == ids, do: :ok, else: {:error, "Backup contains duplicate #{label}"}
  end

  defp ensure_players_reference_games(games, players) do
    game_ids = games |> Enum.map(& &1.id) |> MapSet.new()

    missing =
      players
      |> Enum.reject(&MapSet.member?(game_ids, &1.game_id))
      |> Enum.map(& &1.id)

    if missing == [],
      do: :ok,
      else: {:error, "Players reference missing games: #{inspect(missing)}"}
  end

  defp ensure_audit_events_reference_rows(players, audit_events) do
    player_game_ids = Map.new(players, &{&1.id, &1.game_id})
    audit_ids = audit_events |> Enum.map(& &1.id) |> MapSet.new()

    bad_events =
      Enum.reject(audit_events, fn event ->
        Map.get(player_game_ids, event.player_id) == event.game_id and
          (is_nil(event.origin_event_id) or MapSet.member?(audit_ids, event.origin_event_id))
      end)

    if bad_events == [] do
      :ok
    else
      {:error,
       "Audit events reference missing or mismatched rows: #{inspect(Enum.map(bad_events, & &1.id))}"}
    end
  end

  defp ensure_leaderboard_references_completed_games(games, players, leaderboard_records) do
    games_by_id = Map.new(games, &{&1.id, &1})
    player_game_ids = Map.new(players, &{&1.id, &1.game_id})

    bad_records =
      Enum.reject(leaderboard_records, fn record ->
        game = Map.get(games_by_id, record.game_id)

        game && game.status == "completed" &&
          Map.get(player_game_ids, record.player_id) == record.game_id
      end)

    if bad_records == [] do
      :ok
    else
      {:error,
       "Leaderboard records must reference players in completed games: #{inspect(Enum.map(bad_records, & &1.id))}"}
    end
  end

  defp ensure_completed_games_have_snapshots(games, players, leaderboard_records) do
    player_ids_by_game = grouped_sets(players, :game_id, :id)
    leaderboard_ids_by_game = grouped_sets(leaderboard_records, :game_id, :player_id)

    incomplete =
      games
      |> Enum.filter(&(&1.status == "completed"))
      |> Enum.reject(fn game ->
        winner_ok? =
          game.winner_player_id in MapSet.to_list(
            Map.get(player_ids_by_game, game.id, MapSet.new())
          )

        completed_at_ok? = not is_nil(game.completed_at)
        players = Map.get(player_ids_by_game, game.id, MapSet.new())
        snapshots = Map.get(leaderboard_ids_by_game, game.id, MapSet.new())

        winner_ok? && completed_at_ok? && MapSet.equal?(players, snapshots)
      end)

    if incomplete == [] do
      :ok
    else
      {:error,
       "Completed games must include winner, completed_at, and one leaderboard snapshot per player: #{inspect(Enum.map(incomplete, & &1.id))}"}
    end
  end

  defp grouped_sets(rows, group_key, value_key) do
    Enum.reduce(rows, %{}, fn row, acc ->
      Map.update(
        acc,
        Map.fetch!(row, group_key),
        MapSet.new([Map.fetch!(row, value_key)]),
        fn values ->
          MapSet.put(values, Map.fetch!(row, value_key))
        end
      )
    end)
  end

  defp ensure_import_target_empty_or_replace(true), do: :ok

  defp ensure_import_target_empty_or_replace(false) do
    existing_count =
      Repo.aggregate(Game, :count) +
        Repo.aggregate(Player, :count) +
        Repo.aggregate(AuditEvent, :count) +
        Repo.aggregate(LeaderboardRecord, :count)

    if existing_count == 0 do
      :ok
    else
      {:error, "Database already has Cashflow data; rerun with --replace to import anyway"}
    end
  end

  defp import_backup(prepared, replace?) do
    Repo.transaction(fn ->
      if replace?, do: delete_existing_data()

      %{
        games: insert_all(Game, prepared.games),
        players: insert_all(Player, prepared.players),
        audit_events: insert_all(AuditEvent, prepared.audit_events),
        leaderboard_records: insert_all(LeaderboardRecord, prepared.leaderboard_records)
      }
    end)
  rescue
    error in [Ecto.ConstraintError, Ecto.ChangeError, Ecto.QueryError] ->
      {:error, "Import failed and was rolled back: #{Exception.message(error)}"}
  end

  defp delete_existing_data do
    Repo.delete_all(LeaderboardRecord)
    Repo.delete_all(AuditEvent)
    Repo.delete_all(Player)
    Repo.delete_all(Game)
  end

  defp insert_all(_schema, []), do: 0

  defp insert_all(schema, rows) do
    {count, _} = Repo.insert_all(schema, rows)
    count
  end

  defp require_uuid(map, key) do
    with {:ok, value} <- fetch(map, key),
         {:ok, uuid} <- cast_uuid(value) do
      {:ok, uuid}
    else
      {:error, reason} -> {:error, "#{key} #{reason}"}
    end
  end

  defp optional_uuid(map, key) do
    case Map.get(map, key) do
      nil -> {:ok, nil}
      value -> cast_uuid(value)
    end
  end

  defp cast_uuid(value) do
    case Ecto.UUID.cast(value) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> {:error, "must be a UUID"}
    end
  end

  defp require_string(map, key) do
    with {:ok, value} <- fetch(map, key) do
      if is_binary(value) and String.trim(value) != "" do
        {:ok, value}
      else
        {:error, "#{key} must be a non-empty string"}
      end
    end
  end

  defp require_inclusion(map, key, values) do
    with {:ok, value} <- fetch(map, key) do
      if value in values do
        {:ok, value}
      else
        {:error, "#{key} must be one of #{Enum.join(values, ", ")}"}
      end
    end
  end

  defp require_integer(map, key) do
    with {:ok, value} <- fetch(map, key) do
      if is_integer(value), do: {:ok, value}, else: {:error, "#{key} must be an integer"}
    end
  end

  defp require_datetime(map, key) do
    with {:ok, value} <- fetch(map, key),
         {:ok, datetime} <- parse_datetime(value) do
      {:ok, datetime}
    else
      {:error, reason} -> {:error, "#{key} #{reason}"}
    end
  end

  defp optional_datetime(map, key) do
    case Map.get(map, key) do
      nil -> {:ok, nil}
      value -> parse_datetime(value)
    end
  end

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {:ok, DateTime.truncate(datetime, :second)}
      {:error, _} -> {:error, "must be an ISO8601 datetime"}
    end
  end

  defp parse_datetime(_), do: {:error, "must be an ISO8601 datetime"}

  defp require_sheet(%{"sheet_state" => sheet_state}) when is_map(sheet_state) do
    case Sheets.normalize(sheet_state) do
      {:ok, sheet} -> {:ok, sheet}
      {:error, reason} -> {:error, "sheet_state is invalid: #{inspect(reason)}"}
    end
  end

  defp require_sheet(_), do: {:error, "sheet_state must be an object"}

  defp field_paths(event) do
    paths = Map.get(event, "field_paths", [])

    cond do
      not is_list(paths) or not Enum.all?(paths, &is_binary/1) ->
        {:error, "field_paths must be a list of strings"}

      true ->
        invalid_paths = Enum.reject(paths, &valid_field_path?/1)

        if invalid_paths == [] do
          {:ok, paths}
        else
          {:error, "field_paths contains invalid paths: #{Enum.join(invalid_paths, ", ")}"}
        end
    end
  end

  defp valid_field_path?(path) when path in ["game.status", "game.winner_player_id"], do: true
  defp valid_field_path?(path), do: Sheets.valid_path?(path)

  defp captured_at(record, completed_at) do
    case Map.get(record, "captured_at") do
      nil -> {:ok, completed_at}
      value -> parse_datetime(value)
    end
  end

  defp updated_at(record, fallback) do
    case optional_datetime(record, "updated_at") do
      {:ok, nil} -> fallback
      {:ok, value} -> value
      {:error, _reason} -> fallback
    end
  end

  defp fetch(map, key), do: Map.fetch(map, key) |> fetch_result()
  defp fetch_result({:ok, value}), do: {:ok, value}
  defp fetch_result(:error), do: {:error, "is required"}

  defp integer_or_default(value, _default) when is_integer(value), do: value
  defp integer_or_default(_value, default), do: default

  defp optional_integer(map, key) do
    case Map.get(map, key) do
      value when is_integer(value) -> value
      _ -> nil
    end
  end

  defp game_lock_version("completed"), do: 2
  defp game_lock_version(_status), do: 1

  defp player_lock_version(player, audit_events) do
    exported_version = Map.get(player, "lock_version")

    if is_integer(exported_version) do
      exported_version
    else
      audit_events
      |> Enum.filter(&(&1.player_id == player["id"]))
      |> Enum.map(& &1.resulting_lock_version)
      |> Enum.filter(&is_integer/1)
      |> Enum.max(fn -> 1 end)
    end
  end

  defp summary_or_default(%{"summary" => summary}, _sheet_state) when is_map(summary), do: summary
  defp summary_or_default(_player, sheet_state), do: Games.summary_data(sheet_state)

  defp map_or_default(value, _default) when is_map(value), do: value
  defp map_or_default(_value, default), do: default

  defp map_or_nil(value) when is_map(value), do: value
  defp map_or_nil(_value), do: nil
end
