# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Cashflow.Repo.insert!(%Cashflow.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Cashflow.Games

if Games.list_games() == [] do
  {:ok, active} =
    Games.create_game(%{
      title: "Demo Active Game",
      players: [
        %{"name" => "Henry", "color" => "blue", "profession" => "Pilot"},
        %{"name" => "Ashley", "color" => "green", "profession" => "Doctor"}
      ]
    })

  player = hd(active.players)

  sheet =
    player.sheet_state
    |> put_in(["income", "salary_cents"], 300_000)
    |> put_in(["income", "interest_cents"], 50_000)
    |> put_in(["assets", "savings_cents"], 100_000)

  {:ok, _} =
    Games.save_player_sheet(active.id, player.id, sheet,
      baseline_lock_version: player.lock_version
    )

  {:ok, completed} =
    Games.create_game(%{
      title: "Demo Completed Game",
      players: [
        %{"name" => "Maya", "color" => "purple", "profession" => "Engineer"},
        %{"name" => "Noah", "color" => "orange", "profession" => "Teacher"}
      ]
    })

  winner = hd(completed.players)

  winner_sheet =
    winner.sheet_state
    |> put_in(["income", "salary_cents"], 250_000)
    |> put_in(["income", "interest_cents"], 300_000)
    |> put_in(["assets", "savings_cents"], 500_000)

  {:ok, %{player: winner}} =
    Games.save_player_sheet(completed.id, winner.id, winner_sheet,
      baseline_lock_version: winner.lock_version
    )

  {:ok, _} =
    Games.complete_game(completed.id, %{
      "winner_player_id" => winner.id,
      "winner_comment" => "Demo completion snapshot"
    })
end
