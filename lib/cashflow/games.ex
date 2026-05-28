defmodule Cashflow.Games do
  @moduledoc """
  Public transactional boundary for games, players, audit, and leaderboard records.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Cashflow.{Calculations, Repo, Sheets}
  alias Cashflow.Games.{AuditEvent, Game, LeaderboardRecord, Player}

  @audit_event_types ~w(turn correction phase_transition completion)
  @leaderboard_phases ~w(rat_race fast_track)
  @leaderboard_timeframes %{"7d" => 7, "30d" => 30, "90d" => 90}

  def subscribe_to_game(game_id) do
    Phoenix.PubSub.subscribe(Cashflow.PubSub, game_topic(game_id))
  end

  def list_games do
    Game
    |> order_by([g], desc: g.updated_at)
    |> preload(:players)
    |> Repo.all()
  end

  def list_active_games do
    Game
    |> where([g], g.status == "active")
    |> order_by([g], desc: g.updated_at)
    |> preload(:players)
    |> Repo.all()
  end

  def list_completed_games do
    Game
    |> where([g], g.status == "completed")
    |> order_by([g], desc: g.completed_at)
    |> preload(:players)
    |> Repo.all()
  end

  def get_game!(id) do
    Game
    |> Repo.get!(id)
    |> Repo.preload(players: from(p in Player, order_by: p.inserted_at))
  end

  def get_player!(id), do: Repo.get!(Player, id)

  def create_game(attrs) do
    attrs = stringify_keys(attrs)
    players = Map.get(attrs, "players", [])

    with {:ok, players} <- normalize_roster(players) do
      title = blank_to_default(Map.get(attrs, "title"), "Cashflow Game")
      now = DateTime.utc_now(:second)

      Multi.new()
      |> Multi.insert(:game, Game.changeset(%Game{}, %{title: title, status: "active"}))
      |> Multi.run(:players, fn repo, %{game: game} ->
        players =
          Enum.map(players, fn player_attrs ->
            sheet =
              Sheets.default_sheet(%{
                "meta" => %{"profession" => Map.get(player_attrs, "profession", "")}
              })

            attrs = %{
              game_id: game.id,
              name: player_attrs["name"],
              color: player_attrs["color"],
              profession: Map.get(player_attrs, "profession", ""),
              phase: sheet["phase"],
              sheet_version: sheet["schema_version"],
              sheet_state: sheet,
              summary: summary_data(sheet),
              last_saved_at: now
            }

            %Player{}
            |> Player.create_changeset(attrs)
            |> repo.insert()
          end)

        collect_results(players)
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{game: game}} -> {:ok, get_game!(game.id)}
        {:error, _step, reason, _changes} -> {:error, reason}
      end
    end
  end

  def save_player_sheet(game_id, player_id, sheet, opts \\ []) do
    event_type = opts[:event_type] || "turn"
    notes = opts[:notes]
    origin_event_id = opts[:origin_event_id]
    baseline_lock_version = opts[:baseline_lock_version]

    result =
      Repo.transaction(fn ->
        repo = Repo
        game = repo.get!(Game, game_id)
        player = repo.get_by!(Player, id: player_id, game_id: game_id)

        ensure_active!(repo, game)
        ensure_current!(repo, player, baseline_lock_version)
        validate_origin!(repo, game, player, origin_event_id, event_type)

        sheet =
          case Sheets.normalize(sheet) do
            {:ok, sheet} -> sheet
            {:error, reason} -> repo.rollback({:invalid_sheet, reason})
          end

        diff = Sheets.diff(player.sheet_state, sheet)
        field_paths = diff["field_paths"]

        if field_paths == [] and event_type in ["turn", "correction"] do
          repo.rollback(:no_changes)
        end

        player_changeset =
          Player.sheet_changeset(player, %{
            phase: sheet["phase"],
            sheet_version: sheet["schema_version"],
            sheet_state: sheet,
            summary: summary_data(sheet),
            last_saved_at: DateTime.utc_now(:second)
          })

        player =
          case repo.update(player_changeset) do
            {:ok, player} -> player
            {:error, changeset} -> repo.rollback(changeset)
          end

        audit_attrs = %{
          game_id: game.id,
          player_id: player.id,
          event_type: event_type,
          sheet_schema_version: sheet["schema_version"],
          baseline_lock_version: baseline_lock_version,
          resulting_lock_version: player.lock_version,
          field_paths: field_paths,
          changes: %{"changes" => diff["changes"]},
          before_snapshot: diff["before_snapshot"],
          after_snapshot: diff["after_snapshot"],
          notes: notes,
          origin_event_id: origin_event_id
        }

        event =
          %AuditEvent{}
          |> AuditEvent.changeset(audit_attrs)
          |> repo.insert!()

        %{player: player, audit_event: event}
      end)

    broadcast_game_update(result, game_id)
  end

  def transition_player_to_fast_track(game_id, player_id, baseline_lock_version) do
    player = Repo.get_by!(Player, id: player_id, game_id: game_id)

    if Calculations.eligible_for_fast_track?(player.sheet_state) do
      sheet = Sheets.transition_to_fast_track(player.sheet_state)

      save_player_sheet(game_id, player_id, sheet,
        event_type: "phase_transition",
        baseline_lock_version: baseline_lock_version,
        notes: "Moved to Fast Track"
      )
    else
      {:error, :not_fast_track_eligible}
    end
  end

  def complete_game(game_id, attrs) do
    attrs = stringify_keys(attrs)
    winner_player_id = Map.get(attrs, "winner_player_id")
    winner_comment = Map.get(attrs, "winner_comment")
    completed_at = DateTime.utc_now(:second)

    result =
      Repo.transaction(fn ->
        repo = Repo

        game =
          Game
          |> repo.get!(game_id)
          |> repo.preload(:players)

        ensure_active!(repo, game)

        winner =
          Enum.find(game.players, &(&1.id == winner_player_id)) ||
            repo.rollback(:invalid_winner)

        game =
          game
          |> Game.complete_changeset(%{
            status: "completed",
            completed_at: completed_at,
            winner_player_id: winner.id,
            winner_comment: winner_comment
          })
          |> repo.update!()

        records =
          Enum.map(game.players, fn player ->
            summary = Calculations.summary(player.sheet_state)

            %LeaderboardRecord{}
            |> LeaderboardRecord.changeset(%{
              game_id: game.id,
              player_id: player.id,
              player_name: player.name,
              game_title: game.title,
              phase: summary.phase,
              cash_cents: summary.cash_cents,
              passive_income_cents: summary.passive_income_cents,
              total_income_cents: summary.total_income_cents,
              total_expenses_cents: summary.total_expenses_cents,
              cashflow_cents: summary.cashflow_cents,
              winner_comment: if(player.id == winner.id, do: winner_comment),
              captured_at: completed_at,
              completed_at: completed_at
            })
            |> repo.insert!()
          end)

        %AuditEvent{}
        |> AuditEvent.changeset(%{
          game_id: game.id,
          player_id: winner.id,
          event_type: "completion",
          sheet_schema_version: winner.sheet_version,
          baseline_lock_version: winner.lock_version,
          resulting_lock_version: winner.lock_version,
          field_paths: ["game.status", "game.winner_player_id"],
          notes: winner_comment
        })
        |> repo.insert!()

        %{game: game, leaderboard_records: records}
      end)

    broadcast_game_update(result, game_id)
  end

  def audit_event_types, do: @audit_event_types

  def leaderboard_phases, do: @leaderboard_phases

  def leaderboard_timeframes, do: Map.keys(@leaderboard_timeframes)

  def list_audit_events(game_id, opts \\ []) do
    opts = opts_map(opts)
    limit = integer_option(opts, :limit, 10, 100)

    AuditEvent
    |> where([e], e.game_id == ^game_id)
    |> filter_binary_id(:player_id, opts[:player_id])
    |> filter_audit_event_type(opts[:event_type])
    |> order_by([e], desc: e.inserted_at)
    |> limit(^limit)
    |> preload(:player)
    |> Repo.all()
  end

  def count_audit_events(game_id, opts \\ []) do
    opts = opts_map(opts)

    AuditEvent
    |> where([e], e.game_id == ^game_id)
    |> filter_binary_id(:player_id, opts[:player_id])
    |> filter_audit_event_type(opts[:event_type])
    |> Repo.aggregate(:count, :id)
  end

  def get_audit_event!(game_id, event_id) do
    AuditEvent
    |> where([e], e.game_id == ^game_id and e.id == ^event_id)
    |> preload(:player)
    |> Repo.one!()
  end

  def list_leaderboard_records(opts \\ []) do
    opts = opts_map(opts)

    LeaderboardRecord
    |> filter_binary_id(:game_id, opts[:game_id])
    |> filter_leaderboard_player(opts[:player_name])
    |> filter_leaderboard_phase(opts[:phase])
    |> filter_leaderboard_timeframe(opts[:timeframe])
    |> order_by([r], desc: r.cashflow_cents, asc: r.completed_at)
    |> Repo.all()
  end

  def leaderboard_filter_options do
    %{
      player_names:
        LeaderboardRecord
        |> select([r], r.player_name)
        |> distinct(true)
        |> order_by([r], asc: r.player_name)
        |> Repo.all(),
      phases:
        LeaderboardRecord
        |> select([r], r.phase)
        |> distinct(true)
        |> order_by([r], asc: r.phase)
        |> Repo.all()
    }
  end

  def export_data do
    %{
      schema_version: Sheets.schema_version(),
      exported_at: DateTime.utc_now(:second) |> DateTime.to_iso8601(),
      games: Game |> order_by([g], asc: g.inserted_at) |> Repo.all() |> Enum.map(&export_game/1),
      players:
        Player |> order_by([p], asc: p.inserted_at) |> Repo.all() |> Enum.map(&export_player/1),
      audit_events:
        AuditEvent
        |> order_by([e], asc: e.inserted_at)
        |> Repo.all()
        |> Enum.map(&export_audit_event/1),
      leaderboard_records:
        LeaderboardRecord
        |> order_by([r], asc: r.inserted_at)
        |> Repo.all()
        |> Enum.map(&export_leaderboard_record/1)
    }
  end

  def summary_data(sheet) do
    sheet
    |> Calculations.summary()
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
  end

  defp broadcast_game_update({:ok, _} = result, game_id) do
    Phoenix.PubSub.broadcast(Cashflow.PubSub, game_topic(game_id), {:game_updated, game_id})
    result
  end

  defp broadcast_game_update(result, _game_id), do: result

  defp game_topic(game_id), do: "games:#{game_id}"

  defp normalize_roster(players) when is_list(players) do
    active_players =
      players
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&(String.trim(Map.get(&1, "name", "")) != ""))

    cond do
      length(active_players) < 2 ->
        {:error, :not_enough_players}

      length(active_players) > 6 ->
        {:error, :too_many_players}

      not unique_by?(active_players, fn player -> String.downcase(String.trim(player["name"])) end) ->
        {:error, :duplicate_player_names}

      not unique_by?(active_players, & &1["color"]) ->
        {:error, :duplicate_player_colors}

      true ->
        {:ok, active_players}
    end
  end

  defp normalize_roster(_), do: {:error, :invalid_players}

  defp unique_by?(items, fun),
    do: items |> Enum.map(fun) |> Enum.uniq() |> length() == length(items)

  defp opts_map(opts) when is_map(opts) do
    Map.new(opts, fn {key, value} -> {normalize_opt_key(key), blank_to_nil(value)} end)
  end

  defp opts_map(opts) when is_list(opts) do
    opts
    |> Map.new()
    |> opts_map()
  end

  defp opts_map(_), do: %{}

  defp normalize_opt_key(key) when is_atom(key), do: key
  defp normalize_opt_key("event_type"), do: :event_type
  defp normalize_opt_key("game_id"), do: :game_id
  defp normalize_opt_key("limit"), do: :limit
  defp normalize_opt_key("phase"), do: :phase
  defp normalize_opt_key("player_id"), do: :player_id
  defp normalize_opt_key("player_name"), do: :player_name
  defp normalize_opt_key("timeframe"), do: :timeframe
  defp normalize_opt_key(key) when is_binary(key), do: key
  defp normalize_opt_key(key), do: key

  defp blank_to_nil(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      value -> value
    end
  end

  defp blank_to_nil(value), do: value

  defp integer_option(opts, key, default, max) do
    value = Map.get(opts, key)

    case value do
      integer when is_integer(integer) ->
        integer

      string when is_binary(string) ->
        case Integer.parse(string) do
          {integer, ""} -> integer
          _ -> default
        end

      _ ->
        default
    end
    |> min(max)
    |> max(1)
  end

  defp filter_binary_id(query, _field, nil), do: query

  defp filter_binary_id(query, field, value) do
    case Ecto.UUID.cast(value) do
      {:ok, uuid} -> where(query, [record], field(record, ^field) == ^uuid)
      :error -> where(query, false)
    end
  end

  defp filter_audit_event_type(query, nil), do: query

  defp filter_audit_event_type(query, event_type) when event_type in @audit_event_types,
    do: where(query, [e], e.event_type == ^event_type)

  defp filter_audit_event_type(query, _event_type), do: where(query, false)

  defp filter_leaderboard_player(query, nil), do: query

  defp filter_leaderboard_player(query, player_name),
    do: where(query, [r], r.player_name == ^player_name)

  defp filter_leaderboard_phase(query, nil), do: query

  defp filter_leaderboard_phase(query, phase) when phase in @leaderboard_phases,
    do: where(query, [r], r.phase == ^phase)

  defp filter_leaderboard_phase(query, _phase), do: where(query, false)

  defp filter_leaderboard_timeframe(query, nil), do: query
  defp filter_leaderboard_timeframe(query, "all"), do: query

  defp filter_leaderboard_timeframe(query, timeframe) do
    case Map.fetch(@leaderboard_timeframes, timeframe) do
      {:ok, days} ->
        cutoff = DateTime.utc_now(:second) |> DateTime.add(-days, :day)
        where(query, [r], r.completed_at >= ^cutoff)

      :error ->
        where(query, false)
    end
  end

  defp collect_results(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {:ok, record}, {:ok, records} -> {:cont, {:ok, [record | records]}}
      {:error, reason}, _ -> {:halt, {:error, reason}}
    end)
  end

  defp ensure_active!(_repo, %Game{status: "active"}), do: :ok
  defp ensure_active!(repo, %Game{}), do: repo.rollback(:completed_game)

  defp ensure_current!(_repo, _player, nil), do: :ok

  defp ensure_current!(repo, %Player{lock_version: current}, baseline) when current != baseline do
    repo.rollback({:stale, current})
  end

  defp ensure_current!(_repo, _player, _baseline), do: :ok

  defp validate_origin!(repo, _game, _player, nil, "correction"),
    do: repo.rollback(:invalid_origin_event)

  defp validate_origin!(_repo, _game, _player, nil, _event_type), do: :ok

  defp validate_origin!(repo, game, player, origin_event_id, "correction") do
    case repo.get(AuditEvent, origin_event_id) do
      %AuditEvent{game_id: game_id, player_id: player_id}
      when game_id == game.id and player_id == player.id ->
        :ok

      _ ->
        repo.rollback(:invalid_origin_event)
    end
  end

  defp validate_origin!(repo, _game, _player, _origin_event_id, _event_type) do
    repo.rollback(:origin_requires_correction)
  end

  defp blank_to_default(value, default) when is_binary(value) do
    if String.trim(value) == "", do: default, else: String.trim(value)
  end

  defp blank_to_default(_value, default), do: default

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(value) when is_list(value), do: Enum.map(value, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp export_game(game) do
    %{
      id: game.id,
      title: game.title,
      status: game.status,
      completed_at: iso8601(game.completed_at),
      winner_player_id: game.winner_player_id,
      winner_comment: game.winner_comment,
      inserted_at: iso8601(game.inserted_at),
      updated_at: iso8601(game.updated_at)
    }
  end

  defp export_player(player) do
    %{
      id: player.id,
      game_id: player.game_id,
      name: player.name,
      color: player.color,
      profession: player.profession,
      phase: player.phase,
      sheet_version: player.sheet_version,
      sheet_state: player.sheet_state,
      summary: player.summary,
      last_saved_at: iso8601(player.last_saved_at),
      inserted_at: iso8601(player.inserted_at),
      updated_at: iso8601(player.updated_at)
    }
  end

  defp export_audit_event(event) do
    %{
      id: event.id,
      game_id: event.game_id,
      player_id: event.player_id,
      event_type: event.event_type,
      sheet_schema_version: event.sheet_schema_version,
      baseline_lock_version: event.baseline_lock_version,
      resulting_lock_version: event.resulting_lock_version,
      field_paths: event.field_paths_data["paths"] || [],
      changes: event.changes,
      notes: event.notes,
      origin_event_id: event.origin_event_id,
      inserted_at: iso8601(event.inserted_at)
    }
  end

  defp export_leaderboard_record(record) do
    %{
      id: record.id,
      game_id: record.game_id,
      player_id: record.player_id,
      game_title: record.game_title,
      player_name: record.player_name,
      phase: record.phase,
      cash_cents: record.cash_cents,
      passive_income_cents: record.passive_income_cents,
      total_income_cents: record.total_income_cents,
      total_expenses_cents: record.total_expenses_cents,
      cashflow_cents: record.cashflow_cents,
      winner_comment: record.winner_comment,
      completed_at: iso8601(record.completed_at),
      inserted_at: iso8601(record.inserted_at)
    }
  end

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)

  defp iso8601(%NaiveDateTime{} = value),
    do: value |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601()
end
