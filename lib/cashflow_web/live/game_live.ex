defmodule CashflowWeb.GameLive do
  use CashflowWeb, :live_view

  alias Cashflow.{Calculations, Games}
  import CashflowWeb.FormatHelpers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, load(socket, id)}
  end

  @impl true
  def handle_event("complete", %{"game" => params}, socket) do
    case Games.complete_game(socket.assigns.game.id, params) do
      {:ok, %{game: game}} ->
        {:noreply, socket |> put_flash(:info, "Game completed.") |> load(game.id)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not complete game: #{inspect(reason)}")}
    end
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

  defp load(socket, id) do
    game = Games.get_game!(id)

    assign(socket,
      game: game,
      player_summaries: Map.new(game.players, &{&1.id, Calculations.summary(&1.sheet_state)})
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
          </div>
        </header>

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
            phx-submit="complete"
            class="grid gap-3 md:grid-cols-[1fr_2fr_auto]"
          >
            <.input
              name="game[winner_player_id]"
              type="select"
              label="Winner"
              value=""
              options={Enum.map(@game.players, &{&1.name, &1.id})}
            />
            <.input name="game[winner_comment]" label="Comment" value="" />
            <div class="flex items-end"><.button type="submit">Complete</.button></div>
          </.form>
        </section>
      </section>
    </main>
    """
  end
end
