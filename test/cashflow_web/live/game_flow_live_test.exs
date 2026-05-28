defmodule CashflowWeb.GameFlowLiveTest do
  use CashflowWeb.ConnCase, async: false

  alias Cashflow.Games

  test "dashboard and player sheet render for an active game", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Live Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

    assert html =~ "Live Game"
    assert html =~ "Open Sheet"

    player = hd(game.players)
    {:ok, _view, html} = live(conn, ~p"/games/#{game.id}/players/#{player.id}")

    assert html =~ player.name
    assert html =~ "Rat Race Sheet"
    assert html =~ "Review"
  end

  test "fast track player sheet renders phase-specific fields", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Fast Track Live Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)
    eligible_sheet = put_in(player.sheet_state, ["income", "interest_cents"], 500_000)

    {:ok, %{player: rat_race_player}} =
      Games.save_player_sheet(game.id, player.id, eligible_sheet,
        baseline_lock_version: player.lock_version
      )

    {:ok, %{player: fast_track_player}} =
      Games.transition_player_to_fast_track(
        game.id,
        rat_race_player.id,
        rat_race_player.lock_version
      )

    {:ok, _view, html} = live(conn, ~p"/games/#{game.id}/players/#{fast_track_player.id}")

    assert html =~ "Fast Track Sheet"
    assert html =~ "Cashflow Day Income"
    refute html =~ "Mortgage Liability"
  end

  test "reviewed sheet saves preserve notes", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Notes Live Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)
    {:ok, view, _html} = live(conn, ~p"/games/#{game.id}/players/#{player.id}")

    html =
      render_submit(view, "review", %{
        "sheet" => %{"salary" => "$3,100", "notes" => "Payday review note"}
      })

    assert html =~ "Payday review note"
    assert html =~ "sheet[notes]"

    render_submit(view, "save", %{"sheet" => %{"salary" => "$3,100"}})

    [event | _] = Games.list_audit_events(game.id)

    assert event.notes == "Payday review note"
  end

  test "new game setup route renders", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/games/new")

    assert html =~ "Set Up Players"
    assert html =~ "Create Game"
  end

  test "audit and leaderboard routes render", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Completed Live Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)
    {:ok, _} = Games.complete_game(game.id, %{"winner_player_id" => player.id})

    {:ok, _view, audit_html} = live(conn, ~p"/games/#{game.id}/audit")
    {:ok, _view, leaderboard_html} = live(conn, ~p"/leaderboard")

    assert audit_html =~ "Audit Timeline"
    assert leaderboard_html =~ "Completion Snapshots"
    assert leaderboard_html =~ "Completed Live Game"
  end
end
