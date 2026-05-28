defmodule Cashflow.GamesTest do
  use Cashflow.DataCase, async: false

  alias Cashflow.Games
  alias Cashflow.Games.AuditEvent

  describe "create_game/1" do
    test "creates an active game with normalized players and sheets" do
      assert {:ok, game} =
               Games.create_game(%{
                 title: "Friday Cashflow",
                 players: [
                   %{"name" => "Henry", "color" => "blue", "profession" => "Pilot"},
                   %{"name" => "Ashley", "color" => "green", "profession" => "Doctor"}
                 ]
               })

      assert game.status == "active"
      assert length(game.players) == 2
      assert Enum.all?(game.players, &(&1.sheet_version == 1))
    end

    test "rejects duplicate player names case-insensitively" do
      assert {:error, :duplicate_player_names} =
               Games.create_game(%{
                 players: [
                   %{"name" => "Henry", "color" => "blue"},
                   %{"name" => "henry", "color" => "green"}
                 ]
               })
    end
  end

  test "saving a player sheet writes audit and rejects stale drafts" do
    {:ok, game} = fixture_game()
    player = hd(game.players)

    sheet =
      player.sheet_state
      |> put_in(["income", "salary_cents"], 300_000)
      |> put_in(["assets", "savings_cents"], 50_000)

    assert {:ok, %{player: updated, audit_event: event}} =
             Games.save_player_sheet(game.id, player.id, sheet,
               baseline_lock_version: player.lock_version
             )

    assert updated.lock_version == player.lock_version + 1
    assert event.event_type == "turn"
    assert "income.salary_cents" in event.field_paths_data["paths"]

    newer_sheet = put_in(sheet, ["assets", "savings_cents"], 60_000)

    assert {:error, {:stale, current_version}} =
             Games.save_player_sheet(game.id, player.id, newer_sheet,
               baseline_lock_version: player.lock_version
             )

    assert current_version == updated.lock_version
  end

  test "saving a player sheet broadcasts game updates" do
    {:ok, game} = fixture_game()
    player = hd(game.players)
    game_id = game.id

    :ok = Games.subscribe_to_game(game_id)

    sheet = put_in(player.sheet_state, ["income", "salary_cents"], 300_000)

    assert {:ok, _} =
             Games.save_player_sheet(game_id, player.id, sheet,
               baseline_lock_version: player.lock_version
             )

    assert_receive {:game_updated, ^game_id}
  end

  test "completion snapshots leaderboard and blocks later sheet saves" do
    {:ok, game} = fixture_game()
    player = hd(game.players)

    sheet =
      player.sheet_state
      |> put_in(["income", "salary_cents"], 300_000)
      |> put_in(["income", "interest_cents"], 20_000)

    {:ok, %{player: player}} =
      Games.save_player_sheet(game.id, player.id, sheet,
        baseline_lock_version: player.lock_version
      )

    assert {:ok, %{game: completed, leaderboard_records: records}} =
             Games.complete_game(game.id, %{
               "winner_player_id" => player.id,
               "winner_comment" => "Won big"
             })

    assert completed.status == "completed"
    assert length(records) == 2

    assert {:error, :completed_game} =
             Games.save_player_sheet(
               game.id,
               player.id,
               put_in(player.sheet_state, ["income", "salary_cents"], 400_000),
               baseline_lock_version: player.lock_version
             )

    assert [%{winner_comment: "Won big"}] =
             Games.list_leaderboard_records()
             |> Enum.filter(&(&1.player_id == player.id))
  end

  test "audit event queries filter by player, type, and limit" do
    {:ok, game} = fixture_game()
    [first_player, second_player] = game.players

    first_sheet = put_in(first_player.sheet_state, ["income", "salary_cents"], 300_000)
    second_sheet = put_in(second_player.sheet_state, ["income", "salary_cents"], 400_000)

    {:ok, _} =
      Games.save_player_sheet(game.id, first_player.id, first_sheet,
        baseline_lock_version: first_player.lock_version
      )

    {:ok, _} =
      Games.save_player_sheet(game.id, second_player.id, second_sheet,
        baseline_lock_version: second_player.lock_version
      )

    assert [%{player_id: player_id}] =
             Games.list_audit_events(game.id, player_id: first_player.id, limit: 10)

    assert player_id == first_player.id
    assert 2 == Games.count_audit_events(game.id)
    assert 1 == Games.count_audit_events(game.id, player_id: first_player.id)
    assert 2 == length(Games.list_audit_events(game.id, event_type: "turn", limit: 10))
    assert 1 == length(Games.list_audit_events(game.id, limit: 1))
    assert [] == Games.list_audit_events(game.id, event_type: "bogus")
  end

  test "leaderboard queries filter by player, phase, game, and timeframe" do
    {:ok, first_game} =
      Games.create_game(%{
        title: "First Completed Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    {:ok, second_game} =
      Games.create_game(%{
        title: "Second Completed Game",
        players: [
          %{"name" => "Taylor", "color" => "blue"},
          %{"name" => "Morgan", "color" => "green"}
        ]
      })

    {:ok, _} =
      Games.complete_game(first_game.id, %{"winner_player_id" => hd(first_game.players).id})

    {:ok, _} =
      Games.complete_game(second_game.id, %{"winner_player_id" => hd(second_game.players).id})

    assert [%{game_id: game_id} | _] = Games.list_leaderboard_records(game_id: first_game.id)
    assert game_id == first_game.id

    assert [%{player_name: "Taylor"}] = Games.list_leaderboard_records(player_name: "Taylor")
    assert length(Games.list_leaderboard_records(phase: "rat_race")) == 4
    assert length(Games.list_leaderboard_records(timeframe: "90d")) == 4
    assert [] == Games.list_leaderboard_records(phase: "fast_track")

    assert %{player_names: player_names, phases: ["rat_race"]} =
             Games.leaderboard_filter_options()

    assert "Henry" in player_names
    assert "Taylor" in player_names
  end

  test "corrections require a same-player origin event" do
    {:ok, game} = fixture_game()
    player = hd(game.players)
    sheet = put_in(player.sheet_state, ["income", "salary_cents"], 300_000)

    assert {:error, :invalid_origin_event} =
             Games.save_player_sheet(game.id, player.id, sheet,
               event_type: "correction",
               baseline_lock_version: player.lock_version
             )
  end

  test "audit events reject field paths outside the versioned schema" do
    changeset =
      AuditEvent.changeset(%AuditEvent{}, %{
        game_id: Ecto.UUID.generate(),
        player_id: Ecto.UUID.generate(),
        event_type: "turn",
        sheet_schema_version: 1,
        field_paths: ["income.salary_cents", "income.bonus_cents"]
      })

    refute changeset.valid?

    assert %{field_paths_data: ["contains invalid paths: income.bonus_cents"]} =
             errors_on(changeset)
  end

  defp fixture_game do
    Games.create_game(%{
      title: "Fixture Game",
      players: [
        %{"name" => "Henry", "color" => "blue"},
        %{"name" => "Ashley", "color" => "green"}
      ]
    })
  end
end
