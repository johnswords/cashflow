defmodule CashflowWeb.BackupController do
  use CashflowWeb, :controller

  alias Cashflow.Games

  def show(conn, _params) do
    json(conn, Games.export_data())
  end
end
