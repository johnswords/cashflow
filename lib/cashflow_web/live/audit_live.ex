defmodule CashflowWeb.AuditLive do
  use CashflowWeb, :live_view

  alias Cashflow.{Games, Sheets}

  @audit_page_size 10

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Games.subscribe_to_game(id)

    game = Games.get_game!(id)

    {:ok,
     socket
     |> assign(:game, game)
     |> assign(:audit_filters, %{})
     |> assign(:audit_limit, @audit_page_size)
     |> assign(:events, [])
     |> assign(:events_total_count, 0)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    filters = normalize_audit_filters(params, socket.assigns.game)

    {:noreply,
     socket
     |> assign(:audit_filters, filters)
     |> assign(:audit_limit, @audit_page_size)
     |> load_events()}
  end

  @impl true
  def handle_event("filter", %{"filters" => params}, socket) do
    query = audit_query(params, socket.assigns.game)

    {:noreply, push_patch(socket, to: ~p"/games/#{socket.assigns.game.id}/audit?#{query}")}
  end

  def handle_event("load_more", _params, socket) do
    {:noreply,
     socket
     |> assign(:audit_limit, socket.assigns.audit_limit + @audit_page_size)
     |> load_events()}
  end

  @impl true
  def handle_info({:game_updated, game_id}, socket) do
    {:noreply,
     socket
     |> assign(:game, Games.get_game!(game_id))
     |> load_events()}
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

        <section class="rounded-lg bg-base-100 p-4 shadow-sm">
          <.form
            for={%{}}
            as={:filters}
            phx-change="filter"
            phx-submit="filter"
            class="grid gap-3 md:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_auto]"
          >
            <.input
              type="select"
              name="filters[player_id]"
              label="Player"
              prompt="All players"
              value={@audit_filters[:player_id] || ""}
              options={Enum.map(@game.players, &{&1.name, &1.id})}
            />
            <.input
              type="select"
              name="filters[event_type]"
              label="Event"
              prompt="All events"
              value={@audit_filters[:event_type] || ""}
              options={Enum.map(Games.audit_event_types(), &{event_label(&1), &1})}
            />
            <div class="flex items-end">
              <.button patch={~p"/games/#{@game.id}/audit"}>Clear</.button>
            </div>
          </.form>
          <p class="text-sm text-base-content/70">
            Showing {length(@events)} of {@events_total_count} events
          </p>
        </section>

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
          <li
            :if={@events == []}
            class="rounded border border-dashed border-base-300 bg-base-100 p-6 text-center text-base-content/70"
          >
            No audit events yet.
          </li>
        </ol>

        <div :if={length(@events) < @events_total_count} class="flex justify-center">
          <.button type="button" phx-click="load_more">
            Load More ({length(@events)} of {@events_total_count})
          </.button>
        </div>
      </section>
    </main>
    """
  end

  defp load_events(socket) do
    game_id = socket.assigns.game.id
    filters = socket.assigns.audit_filters
    limit = socket.assigns.audit_limit
    opts = Map.put(filters, :limit, limit)

    socket
    |> assign(:events, Games.list_audit_events(game_id, opts))
    |> assign(:events_total_count, Games.count_audit_events(game_id, filters))
  end

  defp audit_query(params, game) do
    params
    |> normalize_audit_filters(game)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp normalize_audit_filters(params, game) do
    player_id = params["player_id"] || params[:player_id]
    event_type = params["event_type"] || params[:event_type]

    %{
      player_id: valid_player_id(player_id, game),
      event_type: valid_event_type(event_type)
    }
  end

  defp valid_player_id(player_id, game) do
    if Enum.any?(game.players, &(&1.id == player_id)), do: player_id
  end

  defp valid_event_type(event_type) when event_type in ["", nil], do: nil

  defp valid_event_type(event_type) do
    if event_type in Games.audit_event_types(), do: event_type
  end

  defp event_label(event_type), do: Phoenix.Naming.humanize(event_type || "")

  defp event_time(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp field_label("game.status"), do: "Game Status"
  defp field_label("game.winner_player_id"), do: "Winner"
  defp field_label(path), do: Sheets.field_label(path)

  defp short_id(nil), do: ""
  defp short_id(id), do: String.slice(id, 0, 8)
end
