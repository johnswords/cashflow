defmodule CashflowWeb.LobbyLiveTest do
  use CashflowWeb.ConnCase

  test "GET / renders the LiveView lobby", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "Game Control Room"
    assert html =~ "New Game"
    assert html =~ "Export Backup"
    assert html =~ ~s(href="/backup.json")
  end
end
