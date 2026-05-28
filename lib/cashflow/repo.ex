defmodule Cashflow.Repo do
  use Ecto.Repo,
    otp_app: :cashflow,
    adapter: Ecto.Adapters.SQLite3
end
