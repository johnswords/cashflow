defmodule CashflowWeb.LeaderboardLive do
  use CashflowWeb, :live_view

  alias Cashflow.Games
  import CashflowWeb.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, records: Games.list_leaderboard_records())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 px-4 py-6">
      <section class="mx-auto grid max-w-5xl gap-5">
        <header class="flex items-center justify-between rounded-lg bg-base-100 p-4 shadow-sm">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-primary">Leaderboard</p>
            <h1 class="text-3xl font-bold">Completion Snapshots</h1>
          </div>
          <.button navigate={~p"/"}>Lobby</.button>
        </header>

        <div class="overflow-hidden rounded-lg bg-base-100 shadow-sm">
          <table class="table">
            <thead>
              <tr>
                <th>Rank</th>
                <th>Player</th>
                <th>Game</th>
                <th>Phase</th>
                <th>Cashflow</th>
                <th>Completed</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={{record, index} <- Enum.with_index(@records, 1)}>
                <td>{index}</td>
                <td>{record.player_name}</td>
                <td>
                  <.link navigate={~p"/games/#{record.game_id}"} class="font-semibold text-primary">
                    {record.game_title}
                  </.link>
                </td>
                <td>{phase_label(record.phase)}</td>
                <td>{money(record.cashflow_cents)}</td>
                <td>{Calendar.strftime(record.completed_at, "%Y-%m-%d")}</td>
              </tr>
            </tbody>
          </table>
          <p :if={@records == []} class="p-6 text-center text-base-content/70">
            No completed games yet.
          </p>
        </div>
      </section>
    </main>
    """
  end
end
