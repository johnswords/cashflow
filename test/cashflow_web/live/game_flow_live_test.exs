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
    assert html =~ "Real Estate"
    assert html =~ "Stocks / Mutual Funds / CDs"
    assert html =~ "Review"
  end

  test "rat race player sheet saves investment rows", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Investment Live Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)
    {:ok, view, _html} = live(conn, ~p"/games/#{game.id}/players/#{player.id}")

    html =
      render_submit(view, "review", %{
        "sheet" => %{
          "investments" => %{
            "real_estate" => %{
              "0" => %{
                "name" => "Duplex",
                "down_payment" => "$5,000",
                "cost" => "$60,000",
                "mortgage" => "$55,000",
                "income" => "$250"
              }
            },
            "businesses" => %{
              "0" => %{
                "name" => "Car Wash",
                "down_payment" => "$2,000",
                "cost" => "$12,000",
                "liability" => "$10,000",
                "income" => "$400"
              }
            },
            "stocks" => %{
              "0" => %{"name" => "OK4U", "shares" => "12", "cost_per_share" => "$10"}
            }
          },
          "notes" => "Bought assets"
        }
      })

    assert html =~ "investments.real_estate.0.name"
    assert html =~ "investments.businesses.0.income_cents"
    assert html =~ "investments.stocks.0.shares"

    render_submit(view, "save", %{"sheet" => %{}})

    updated_player =
      game.id
      |> Games.get_game!()
      |> Map.fetch!(:players)
      |> Enum.find(&(&1.id == player.id))

    assert get_in(updated_player.sheet_state, [
             "investments",
             "real_estate",
             Access.at(0),
             "name"
           ]) == "Duplex"

    assert get_in(updated_player.sheet_state, [
             "investments",
             "real_estate",
             Access.at(0),
             "income_cents"
           ]) == 25_000

    assert get_in(updated_player.sheet_state, [
             "investments",
             "businesses",
             Access.at(0),
             "income_cents"
           ]) == 40_000

    assert get_in(updated_player.sheet_state, ["investments", "stocks", Access.at(0), "shares"]) ==
             12

    assert updated_player.summary["passive_income_cents"] == 65_000
    assert hd(Games.list_audit_events(game.id)).notes == "Bought assets"
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
    assert html =~ "Fast Track Investments"
    assert html =~ "Investment 12"
    refute html =~ "Mortgage Liability"
  end

  test "fast track player sheet saves dream and investment rows", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Fast Track Investments Game",
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

    {:ok, view, _html} = live(conn, ~p"/games/#{game.id}/players/#{fast_track_player.id}")

    html =
      render_submit(view, "review", %{
        "sheet" => %{
          "fast_track" => %{
            "dream" => "Island school",
            "dream_completed" => "true",
            "investments" => %{
              "0" => %{"name" => "Apartment Syndicate", "cashflow" => "$1,200"}
            }
          }
        }
      })

    assert html =~ "fast_track.dream"
    assert html =~ "fast_track.investments.0.cashflow_cents"

    render_submit(view, "save", %{"sheet" => %{}})

    updated_player =
      game.id
      |> Games.get_game!()
      |> Map.fetch!(:players)
      |> Enum.find(&(&1.id == player.id))

    assert get_in(updated_player.sheet_state, ["fast_track", "dream"]) == "Island school"
    assert get_in(updated_player.sheet_state, ["fast_track", "dream_completed"])

    assert get_in(updated_player.sheet_state, [
             "fast_track",
             "investments",
             Access.at(0),
             "name"
           ]) == "Apartment Syndicate"

    assert get_in(updated_player.sheet_state, [
             "fast_track",
             "investments",
             Access.at(0),
             "cashflow_cents"
           ]) == 120_000
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
