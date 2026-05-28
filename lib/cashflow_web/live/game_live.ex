defmodule CashflowWeb.GameLive do
  use CashflowWeb, :live_view

  alias Cashflow.{Calculations, Games}
  import CashflowWeb.FormatHelpers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Games.subscribe_to_game(id)

    {:ok, load(socket, id)}
  end

  @impl true
  def handle_event("complete", %{"game" => params}, socket) do
    case Games.complete_game(socket.assigns.game.id, params) do
      {:ok, %{game: game}} ->
        {:noreply,
         socket
         |> assign(:completion_params, %{})
         |> put_flash(:info, "Game completed.")
         |> load(game.id)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not complete game: #{inspect(reason)}")}
    end
  end

  def handle_event("preview_completion", %{"game" => params}, socket) do
    {:noreply, assign(socket, :completion_params, completion_params(params))}
  end

  def handle_event("transition", %{"player-id" => player_id, "lock-version" => version}, socket) do
    case Games.transition_player_to_fast_track(
           socket.assigns.game.id,
           player_id,
           String.to_integer(version)
         ) do
      {:ok, _} ->
        {:noreply,
         socket |> put_flash(:info, "Player moved to Fast Track.") |> load(socket.assigns.game.id)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not move player: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_info({:game_updated, game_id}, socket) do
    {:noreply, load(socket, game_id)}
  end

  defp load(socket, id) do
    game = Games.get_game!(id)
    completion_params = Map.get(socket.assigns, :completion_params, %{})

    assign(socket,
      game: game,
      player_summaries: Map.new(game.players, &{&1.id, Calculations.summary(&1.sheet_state)}),
      leaderboard_records: Games.list_leaderboard_records(game_id: id),
      completion_params: completion_params
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 px-4 py-6">
      <section class="mx-auto grid max-w-7xl gap-5">
        <header class="flex flex-col gap-4 rounded-lg bg-base-100 p-4 shadow-sm md:flex-row md:items-center md:justify-between">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-primary">
              {status_label(@game.status)}
            </p>
            <h1 class="text-3xl font-bold">{@game.title}</h1>
          </div>
          <div class="flex flex-wrap gap-2">
            <.button navigate={~p"/"}>Lobby</.button>
            <.button navigate={~p"/games/#{@game.id}/audit"}>Audit</.button>
            <.button navigate={~p"/leaderboard"}>Leaderboard</.button>
            <.button href={~p"/backup.json"} download="cashflow-backup.json">Export Backup</.button>
          </div>
        </header>

        <section
          :if={@game.status == "completed"}
          class="min-w-0 rounded-lg bg-base-100 p-4 shadow-sm"
        >
          <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
            <div>
              <p class="text-sm font-semibold uppercase tracking-wide text-primary">
                Completed Recap
              </p>
              <h2 class="text-2xl font-semibold">{winner_name(@game)} won</h2>
              <p class="text-sm text-base-content/70">
                Completed {completed_date(@game.completed_at)}
              </p>
              <p :if={@game.winner_comment} class="mt-2 text-sm">{@game.winner_comment}</p>
            </div>
            <div class="flex flex-wrap gap-2">
              <.button navigate={~p"/games/#{@game.id}/audit"}>Audit Timeline</.button>
              <.button href={~p"/backup.json"} download="cashflow-backup.json">
                Export Backup
              </.button>
            </div>
          </div>

          <div class="mt-4 min-w-0 overflow-x-auto">
            <table class="table min-w-[42rem]">
              <thead>
                <tr>
                  <th>Rank</th>
                  <th>Player</th>
                  <th>Phase</th>
                  <th>Cash</th>
                  <th>Passive</th>
                  <th>Income</th>
                  <th>Expenses</th>
                  <th>Cashflow</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={{record, rank} <- ranked_records(@leaderboard_records)}>
                  <td>{rank}</td>
                  <td>{record.player_name}</td>
                  <td>{phase_label(record.phase)}</td>
                  <td>{money(record.cash_cents)}</td>
                  <td>{money(record.passive_income_cents)}</td>
                  <td>{money(record.total_income_cents)}</td>
                  <td>{money(record.total_expenses_cents)}</td>
                  <td>{money(record.cashflow_cents)}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="grid gap-4 lg:grid-cols-2">
          <article :for={player <- @game.players} class="rounded-lg bg-base-100 p-4 shadow-sm">
            <% summary = @player_summaries[player.id] %>
            <div class="mb-3 flex items-start justify-between gap-3">
              <div>
                <h2 class="text-2xl font-semibold">{player.name}</h2>
                <p class="text-sm text-base-content/70">
                  {player.profession} · {phase_label(player.phase)}
                </p>
              </div>
              <span class={["badge border-0 text-white", player_color_class(player.color)]}>
                {player.color}
              </span>
            </div>

            <dl class="grid grid-cols-2 gap-2 text-sm sm:grid-cols-3">
              <div class="rounded bg-base-200 p-2">
                <dt>Cash</dt>
                <dd class="font-semibold">{money(summary.cash_cents)}</dd>
              </div>
              <div class="rounded bg-base-200 p-2">
                <dt>Salary</dt>
                <dd class="font-semibold">{money(summary.salary_cents)}</dd>
              </div>
              <div class="rounded bg-base-200 p-2">
                <dt>Passive</dt>
                <dd class="font-semibold">{money(summary.passive_income_cents)}</dd>
              </div>
              <div class="rounded bg-base-200 p-2">
                <dt>Income</dt>
                <dd class="font-semibold">{money(summary.total_income_cents)}</dd>
              </div>
              <div class="rounded bg-base-200 p-2">
                <dt>Expenses</dt>
                <dd class="font-semibold">{money(summary.total_expenses_cents)}</dd>
              </div>
              <div class="rounded bg-base-200 p-2">
                <dt>Cashflow</dt>
                <dd class="font-semibold">{money(summary.cashflow_cents)}</dd>
              </div>
            </dl>

            <div class="mt-4 flex flex-wrap gap-2">
              <.button
                :if={@game.status == "active"}
                navigate={~p"/games/#{@game.id}/players/#{player.id}"}
              >
                Open Sheet
              </.button>
              <.button
                :if={@game.status == "completed"}
                navigate={~p"/games/#{@game.id}/players/#{player.id}"}
              >
                View Sheet
              </.button>
              <.button
                :if={
                  @game.status == "active" and player.phase == "rat_race" and
                    summary.eligible_for_fast_track
                }
                phx-click="transition"
                phx-value-player-id={player.id}
                phx-value-lock-version={player.lock_version}
              >
                Fast Track
              </.button>
            </div>
          </article>
        </section>

        <section :if={@game.status == "active"} class="rounded-lg bg-base-100 p-4 shadow-sm">
          <h2 class="mb-3 text-xl font-semibold">Complete Game</h2>
          <.form
            for={%{}}
            as={:game}
            phx-change="preview_completion"
            phx-submit="complete"
            class="grid gap-3 md:grid-cols-[1fr_2fr_auto]"
          >
            <.input
              name="game[winner_player_id]"
              type="select"
              label="Winner"
              prompt="Select winner"
              value={@completion_params["winner_player_id"] || ""}
              options={Enum.map(@game.players, &{&1.name, &1.id})}
            />
            <.input
              name="game[winner_comment]"
              label="Comment"
              value={@completion_params["winner_comment"] || ""}
            />
            <div class="flex items-end">
              <.button type="submit" data-confirm="Complete this game and lock all sheets?">
                Complete
              </.button>
            </div>
          </.form>

          <div class="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            <article
              :for={player <- @game.players}
              class={[
                "rounded border border-base-300 bg-base-200 p-3",
                @completion_params["winner_player_id"] == player.id &&
                  "border-primary ring-2 ring-primary/30"
              ]}
            >
              <% summary = @player_summaries[player.id] %>
              <div class="flex items-start justify-between gap-3">
                <div>
                  <h3 class="font-semibold">{player.name}</h3>
                  <p class="text-sm text-base-content/70">{phase_label(summary.phase)}</p>
                </div>
                <span
                  :if={@completion_params["winner_player_id"] == player.id}
                  class="badge badge-primary"
                >
                  Winner
                </span>
              </div>
              <dl class="mt-3 grid grid-cols-2 gap-2 text-sm">
                <div>
                  <dt class="text-base-content/70">Passive</dt>
                  <dd class="font-semibold">{money(summary.passive_income_cents)}</dd>
                </div>
                <div>
                  <dt class="text-base-content/70">Cashflow</dt>
                  <dd class="font-semibold">{money(summary.cashflow_cents)}</dd>
                </div>
                <div>
                  <dt class="text-base-content/70">Income</dt>
                  <dd class="font-semibold">{money(summary.total_income_cents)}</dd>
                </div>
                <div>
                  <dt class="text-base-content/70">Expenses</dt>
                  <dd class="font-semibold">{money(summary.total_expenses_cents)}</dd>
                </div>
              </dl>
            </article>
          </div>
        </section>
      </section>
    </main>
    """
  end

  defp completion_params(params) do
    %{
      "winner_player_id" => Map.get(params, "winner_player_id", ""),
      "winner_comment" => Map.get(params, "winner_comment", "")
    }
  end

  defp winner_name(game) do
    case Enum.find(game.players, &(&1.id == game.winner_player_id)) do
      nil -> "Winner"
      player -> player.name
    end
  end

  defp completed_date(nil), do: "unknown date"
  defp completed_date(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d")
end
