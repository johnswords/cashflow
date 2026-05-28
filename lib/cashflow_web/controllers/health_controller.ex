defmodule CashflowWeb.HealthController do
  use CashflowWeb, :controller

  alias Cashflow.Repo

  def show(conn, _params) do
    case Repo.query("select 1") do
      {:ok, _result} ->
        json(conn, %{
          status: "ok",
          app: "cashflow",
          database: "ok",
          checked_at: DateTime.utc_now(:second) |> DateTime.to_iso8601()
        })

      {:error, _reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{
          status: "degraded",
          app: "cashflow",
          database: "error",
          checked_at: DateTime.utc_now(:second) |> DateTime.to_iso8601()
        })
    end
  end
end
