defmodule CashflowWeb.HealthControllerTest do
  use CashflowWeb.ConnCase, async: false

  test "GET /healthz returns app and database status", %{conn: conn} do
    conn = get(conn, ~p"/healthz")

    assert %{
             "status" => "ok",
             "app" => "cashflow",
             "database" => "ok",
             "checked_at" => checked_at
           } = json_response(conn, 200)

    assert {:ok, _datetime, 0} = DateTime.from_iso8601(checked_at)
  end

  test "GET /status.json returns the same status payload", %{conn: conn} do
    conn = get(conn, ~p"/status.json")

    assert %{"status" => "ok", "database" => "ok"} = json_response(conn, 200)
  end
end
