defmodule CashflowWeb.LeaderboardLive do
  use CashflowWeb, :live_view

  alias Cashflow.Games
  import CashflowWeb.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:records, [])
     |> assign(:leaderboard_filters, %{})
     |> assign(:filter_options, Games.leaderboard_filter_options())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    filter_options = Games.leaderboard_filter_options()
    filters = normalize_leaderboard_filters(params, filter_options)

    {:noreply,
     socket
     |> assign(:filter_options, filter_options)
     |> assign(:leaderboard_filters, filters)
     |> assign(:records, Games.list_leaderboard_records(filters))}
  end

  @impl true
  def handle_event("filter", %{"filters" => params}, socket) do
    query = leaderboard_query(params, socket.assigns.filter_options)

    {:noreply, push_patch(socket, to: ~p"/leaderboard?#{query}")}
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

        <section class="rounded-lg bg-base-100 p-4 shadow-sm">
          <.form
            for={%{}}
            as={:filters}
            phx-change="filter"
            phx-submit="filter"
            class="grid gap-3 md:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_minmax(0,1fr)_auto]"
          >
            <.input
              type="select"
              name="filters[player_name]"
              label="Player"
              prompt="All players"
              value={@leaderboard_filters[:player_name] || ""}
              options={Enum.map(@filter_options.player_names, &{&1, &1})}
            />
            <.input
              type="select"
              name="filters[phase]"
              label="Phase"
              prompt="All phases"
              value={@leaderboard_filters[:phase] || ""}
              options={Enum.map(@filter_options.phases, &{phase_label(&1), &1})}
            />
            <.input
              type="select"
              name="filters[timeframe]"
              label="Timeframe"
              value={@leaderboard_filters[:timeframe] || "all"}
              options={[
                {"All time", "all"},
                {"Last 7 days", "7d"},
                {"Last 30 days", "30d"},
                {"Last 90 days", "90d"}
              ]}
            />
            <div class="flex items-end">
              <.button patch={~p"/leaderboard"}>Clear</.button>
            </div>
          </.form>
          <p class="text-sm text-base-content/70">
            Showing {length(@records)} completion snapshots
          </p>
        </section>

        <div class="rounded-lg bg-base-100 shadow-sm">
          <div class="overflow-x-auto">
            <table class="table min-w-[42rem]">
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
                <tr :for={{record, rank} <- ranked_records(@records)}>
                  <td>{rank}</td>
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
          </div>
          <p :if={@records == []} class="p-6 text-center text-base-content/70">
            No completed games yet.
          </p>
        </div>
      </section>
    </main>
    """
  end

  defp leaderboard_query(params, options) do
    params
    |> normalize_leaderboard_filters(options)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp normalize_leaderboard_filters(params, options) do
    player_name = params["player_name"] || params[:player_name]
    phase = params["phase"] || params[:phase]
    timeframe = params["timeframe"] || params[:timeframe]

    %{
      player_name: valid_player_name(player_name, options),
      phase: valid_phase(phase, options),
      timeframe: valid_timeframe(timeframe)
    }
  end

  defp valid_player_name(player_name, options) do
    if player_name in options.player_names, do: player_name
  end

  defp valid_phase(phase, options) do
    if phase in options.phases, do: phase
  end

  defp valid_timeframe(timeframe) when timeframe in ["", nil, "all"], do: nil

  defp valid_timeframe(timeframe) do
    if timeframe in Games.leaderboard_timeframes(), do: timeframe
  end
end
