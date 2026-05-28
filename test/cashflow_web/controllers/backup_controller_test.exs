defmodule CashflowWeb.BackupControllerTest do
  use CashflowWeb.ConnCase, async: false

  alias Cashflow.Games

  test "GET /backup.json exports tracked game data", %{conn: conn} do
    {:ok, game} =
      Games.create_game(%{
        title: "Backup Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    conn = get(conn, ~p"/backup.json")

    assert %{"schema_version" => 1, "games" => games, "players" => players} =
             json_response(conn, 200)

    assert Enum.any?(games, &(&1["id"] == game.id))
    assert length(players) == 2
  end
end
