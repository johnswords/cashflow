defmodule Cashflow.GamesTest do
  use Cashflow.DataCase, async: false

  alias Cashflow.Games

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
