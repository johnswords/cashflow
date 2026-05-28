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

    {:ok, view, _html} = live(conn, ~p"/games/#{game.id}/players/#{updated_player.id}")

    html =
      render_submit(view, "review", %{
        "sheet" => %{
          "fast_track" => %{
            "dream" => "Island school"
          }
        }
      })

    assert html =~ "Dream Completed"
    assert html =~ "Yes"
    assert html =~ "No"

    render_submit(view, "save", %{"sheet" => %{}})

    updated_player =
      game.id
      |> Games.get_game!()
      |> Map.fetch!(:players)
      |> Enum.find(&(&1.id == player.id))

    refute get_in(updated_player.sheet_state, ["fast_track", "dream_completed"])
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

    render_click(view, "save")

    [event | _] = Games.list_audit_events(game.id)

    assert event.notes == "Payday review note"
  end

  test "editing after review invalidates save until the current draft is reviewed", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Review Drift Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)
    {:ok, view, _html} = live(conn, ~p"/games/#{game.id}/players/#{player.id}")

    assert render_submit(view, "review", %{"sheet" => %{"salary" => "$3,100"}}) =~ "$3100"

    html = render_change(view, "change", %{"sheet" => %{"salary" => "$3,200"}})

    refute html =~ "Save Reviewed Changes"

    assert render_click(view, "save") =~ "Review the current changes before saving."

    render_submit(view, "review", %{"sheet" => %{"salary" => "$3,200"}})
    render_click(view, "save")

    updated_player =
      game.id
      |> Games.get_game!()
      |> Map.fetch!(:players)
      |> Enum.find(&(&1.id == player.id))

    assert get_in(updated_player.sheet_state, ["income", "salary_cents"]) == 320_000
  end

  test "invalid sheet input surfaces errors instead of silently saving", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Input Error Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)
    {:ok, view, _html} = live(conn, ~p"/games/#{game.id}/players/#{player.id}")

    html =
      render_submit(view, "review", %{
        "sheet" => %{"salary" => "not money", "children_count" => "-1"}
      })

    assert html =~ "Salary must be a money amount."
    assert html =~ "Children must be zero or more."
    refute html =~ "Save Reviewed Changes"
  end

  test "stale sheet save shows a reloadable conflict panel", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Stale Live Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)
    {:ok, view, _html} = live(conn, ~p"/games/#{game.id}/players/#{player.id}")

    external_sheet = put_in(player.sheet_state, ["income", "salary_cents"], 300_000)

    {:ok, _} =
      Games.save_player_sheet(game.id, player.id, external_sheet,
        baseline_lock_version: player.lock_version
      )

    render_submit(view, "review", %{"sheet" => %{"salary" => "$3,200"}})

    html = render_click(view, "save")

    assert html =~ "Sheet changed in another tab"
    assert html =~ "Reload Current Sheet"

    html = render_click(view, "reload_current")

    assert html =~ "$3000"
    refute html =~ "Sheet changed in another tab"
  end

  test "correction route shows origin context and friendly field labels", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Correction Live Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)
    sheet = put_in(player.sheet_state, ["income", "salary_cents"], 300_000)

    {:ok, %{player: player, audit_event: origin_event}} =
      Games.save_player_sheet(game.id, player.id, sheet,
        notes: "Initial salary",
        baseline_lock_version: player.lock_version
      )

    {:ok, view, html} =
      live(conn, ~p"/games/#{game.id}/players/#{player.id}?origin_event_id=#{origin_event.id}")

    assert html =~ "Correction Draft"
    assert html =~ "Origin: Henry"
    assert html =~ "Salary"
    assert html =~ "Initial salary"

    html =
      render_submit(view, "review", %{
        "sheet" => %{"salary" => "$3,200", "notes" => "Fix salary"}
      })

    assert html =~ "Salary"
    assert html =~ "$3000"
    assert html =~ "$3200"

    render_submit(view, "save", %{"sheet" => %{}})

    [correction | _] = Games.list_audit_events(game.id)

    assert correction.event_type == "correction"
    assert correction.origin_event_id == origin_event.id
    assert correction.notes == "Fix salary"

    {:ok, _view, audit_html} = live(conn, ~p"/games/#{game.id}/audit")

    assert audit_html =~ "Correction of event"
    assert audit_html =~ "Salary"
  end

  test "correction draft uses the origin snapshot and preserves later current edits", %{
    conn: conn
  } do
    {:ok, game} =
      Games.create_game(%{
        title: "Correction Snapshot Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)
    salary_sheet = put_in(player.sheet_state, ["income", "salary_cents"], 300_000)

    {:ok, %{player: player, audit_event: origin_event}} =
      Games.save_player_sheet(game.id, player.id, salary_sheet,
        notes: "Original salary",
        baseline_lock_version: player.lock_version
      )

    savings_sheet = put_in(player.sheet_state, ["assets", "savings_cents"], 50_000)

    {:ok, %{player: player}} =
      Games.save_player_sheet(game.id, player.id, savings_sheet,
        notes: "Later savings",
        baseline_lock_version: player.lock_version
      )

    {:ok, view, _html} =
      live(conn, ~p"/games/#{game.id}/players/#{player.id}?origin_event_id=#{origin_event.id}")

    html =
      render_submit(view, "review", %{
        "sheet" => %{"salary" => "$3,200", "notes" => "Fix original salary"}
      })

    assert html =~ "Salary"
    assert html =~ "$3000"
    assert html =~ "$3200"
    refute html =~ "assets.savings_cents"

    render_submit(view, "save", %{"sheet" => %{}})

    updated_player =
      game.id
      |> Games.get_game!()
      |> Map.fetch!(:players)
      |> Enum.find(&(&1.id == player.id))

    assert get_in(updated_player.sheet_state, ["income", "salary_cents"]) == 320_000
    assert get_in(updated_player.sheet_state, ["assets", "savings_cents"]) == 50_000

    [correction | _] = Games.list_audit_events(game.id)

    assert correction.event_type == "correction"
    assert correction.origin_event_id == origin_event.id
    assert correction.field_paths_data["paths"] == ["income.salary_cents"]
  end

  test "dashboard and audit timeline refresh after game writes", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Live Refresh Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)

    {:ok, dashboard, dashboard_html} = live(conn, ~p"/games/#{game.id}")
    {:ok, audit, audit_html} = live(conn, ~p"/games/#{game.id}/audit")

    refute dashboard_html =~ "$3000"
    refute audit_html =~ "Salary"

    sheet = put_in(player.sheet_state, ["income", "salary_cents"], 300_000)

    assert {:ok, _} =
             Games.save_player_sheet(game.id, player.id, sheet,
               baseline_lock_version: player.lock_version
             )

    assert render(dashboard) =~ "$3000"
    assert render(audit) =~ "Salary"
  end

  test "new game setup route renders", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/games/new")

    assert html =~ "Set Up Players"
    assert html =~ "Create Game"
  end

  test "new game setup keeps submitted values after validation error", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/games/new")

    html =
      render_submit(view, "save", %{
        "game" => %{
          "title" => "Friday Error Game",
          "players" => %{
            "0" => %{"name" => "Taylor", "profession" => "Engineer", "color" => "blue"},
            "1" => %{"name" => "Taylor", "profession" => "Pilot", "color" => "green"},
            "2" => %{"name" => "", "profession" => "Optional row", "color" => "purple"}
          }
        }
      })

    assert html =~ "Player names must be unique."
    assert html =~ ~s(value="Friday Error Game")
    assert html =~ ~s(value="Taylor")
    assert html =~ ~s(value="Engineer")
    assert html =~ ~s(value="Pilot")
    assert html =~ ~s(value="Optional row")
  end

  test "new game setup stores players in numeric form row order", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/games/new")

    render_submit(view, "save", %{
      "game" => %{
        "title" => "Roster Order Game",
        "players" => %{
          "10" => %{"name" => "Tenth Row", "profession" => "Pilot", "color" => "green"},
          "2" => %{"name" => "Second Row", "profession" => "Engineer", "color" => "blue"}
        }
      }
    })

    {path, _flash} = assert_redirect(view)
    [_, game_id] = Regex.run(~r{/games/([^/]+)}, path)
    game = Games.get_game!(game_id)

    assert Enum.map(game.players, & &1.name) == ["Second Row", "Tenth Row"]
    assert Enum.map(game.players, & &1.profession) == ["Engineer", "Pilot"]
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

    ranks =
      ~r/<td>\s*(\d+)\s*<\/td>/
      |> Regex.scan(leaderboard_html, capture: :all_but_first)
      |> List.flatten()

    assert Enum.take(ranks, 2) == ["1", "1"]
  end
end
