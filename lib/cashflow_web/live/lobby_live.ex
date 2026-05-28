defmodule CashflowWeb.LobbyLive do
  use CashflowWeb, :live_view

  alias Cashflow.Games
  import CashflowWeb.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, load(socket)}
  end

  defp load(socket) do
    socket
    |> assign(:active_games, Games.list_active_games())
    |> assign(:completed_games, Games.list_completed_games())
    |> assign(:leaderboard_records, Games.list_leaderboard_records() |> Enum.take(5))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 text-base-content">
      <section class="mx-auto flex w-full max-w-7xl flex-col gap-8 px-4 py-6 sm:px-6 lg:px-8">
        <header class="flex flex-col gap-4 border-b border-base-300 pb-5 md:flex-row md:items-end md:justify-between">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-primary">Cashflow Live</p>
            <h1 class="text-3xl font-bold sm:text-4xl">Game Control Room</h1>
          </div>
          <.button navigate={~p"/games/new"}>New Game</.button>
        </header>

        <section class="grid gap-4 lg:grid-cols-[1.4fr_1fr]">
          <div class="rounded-lg bg-base-100 p-4 shadow-sm">
            <div class="mb-3 flex items-center justify-between">
              <h2 class="text-xl font-semibold">Active Games</h2>
              <span class="badge badge-primary">{length(@active_games)}</span>
            </div>
            <div class="grid gap-3">
              <article :for={game <- @active_games} class="rounded border border-base-300 p-3">
                <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <h3 class="font-semibold">{game.title}</h3>
                    <p class="text-sm text-base-content/70">
                      {length(game.players)} players · {status_label(game.status)}
                    </p>
                  </div>
                  <.button navigate={~p"/games/#{game.id}"}>Open</.button>
                </div>
              </article>
              <p
                :if={@active_games == []}
                class="rounded border border-dashed border-base-300 p-6 text-center text-base-content/70"
              >
                No active games yet.
              </p>
            </div>
          </div>

          <div class="rounded-lg bg-base-100 p-4 shadow-sm">
            <div class="mb-3 flex items-center justify-between">
              <h2 class="text-xl font-semibold">Leaderboard</h2>
              <.link navigate={~p"/leaderboard"} class="text-sm font-semibold text-primary">
                View all
              </.link>
            </div>
            <ol class="grid gap-2">
              <li
                :for={{record, rank} <- ranked_records(@leaderboard_records)}
                class="flex items-center justify-between rounded border border-base-300 px-3 py-2"
              >
                <span>{rank}. {record.player_name}</span>
                <strong>{money(record.cashflow_cents)}</strong>
              </li>
              <li
                :if={@leaderboard_records == []}
                class="rounded border border-dashed border-base-300 p-6 text-center text-base-content/70"
              >
                Complete a game to fill the board.
              </li>
            </ol>
          </div>
        </section>

        <section class="rounded-lg bg-base-100 p-4 shadow-sm">
          <h2 class="mb-3 text-xl font-semibold">Completed Recaps</h2>
          <div class="grid gap-3 md:grid-cols-2">
            <article :for={game <- @completed_games} class="rounded border border-base-300 p-3">
              <div class="flex items-center justify-between gap-3">
                <div>
                  <h3 class="font-semibold">{game.title}</h3>
                  <p class="text-sm text-base-content/70">{status_label(game.status)}</p>
                </div>
                <.button navigate={~p"/games/#{game.id}"}>Recap</.button>
              </div>
            </article>
            <p
              :if={@completed_games == []}
              class="rounded border border-dashed border-base-300 p-6 text-center text-base-content/70"
            >
              Completed games will appear here.
            </p>
          </div>
        </section>
      </section>
    </main>
    """
  end
end
