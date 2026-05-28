defmodule CashflowWeb.AuditLive do
  use CashflowWeb, :live_view

  alias Cashflow.{Games, Sheets}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Games.subscribe_to_game(id)

    game = Games.get_game!(id)

    {:ok,
     socket
     |> assign(:game, game)
     |> assign(:events, Games.list_audit_events(id))}
  end

  @impl true
  def handle_info({:game_updated, game_id}, socket) do
    {:noreply,
     socket
     |> assign(:game, Games.get_game!(game_id))
     |> assign(:events, Games.list_audit_events(game_id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 px-4 py-6">
      <section class="mx-auto grid max-w-5xl gap-5">
        <header class="flex items-center justify-between rounded-lg bg-base-100 p-4 shadow-sm">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-primary">Audit Timeline</p>
            <h1 class="text-3xl font-bold">{@game.title}</h1>
          </div>
          <.button navigate={~p"/games/#{@game.id}"}>Dashboard</.button>
        </header>

        <ol class="grid gap-3">
          <li :for={event <- @events} class="rounded-lg bg-base-100 p-4 shadow-sm">
            <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <h2 class="font-semibold">
                  {event.player && event.player.name} · {event_label(event.event_type)}
                </h2>
                <p class="text-sm text-base-content/70">
                  {event_time(event.inserted_at)}
                </p>
              </div>
              <.button
                :if={@game.status == "active" and event.event_type != "completion"}
                navigate={
                  ~p"/games/#{@game.id}/players/#{event.player_id}?origin_event_id=#{event.id}"
                }
              >
                Correct
              </.button>
            </div>
            <p :if={event.notes} class="mt-2 text-sm">{event.notes}</p>
            <p
              :if={event.origin_event_id}
              class="mt-2 text-xs uppercase tracking-wide text-base-content/60"
            >
              Correction of event {short_id(event.origin_event_id)}
            </p>
            <div class="mt-3 flex flex-wrap gap-2">
              <span
                :for={path <- event.field_paths_data["paths"] || []}
                class="badge badge-outline"
                title={path}
              >
                {field_label(path)}
              </span>
            </div>
          </li>
          <p
            :if={@events == []}
            class="rounded border border-dashed border-base-300 bg-base-100 p-6 text-center text-base-content/70"
          >
            No audit events yet.
          </p>
        </ol>
      </section>
    </main>
    """
  end

  defp event_label(event_type), do: Phoenix.Naming.humanize(event_type || "")

  defp event_time(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp field_label("game.status"), do: "Game Status"
  defp field_label("game.winner_player_id"), do: "Winner"
  defp field_label(path), do: Sheets.field_label(path)

  defp short_id(nil), do: ""
  defp short_id(id), do: String.slice(id, 0, 8)
end
