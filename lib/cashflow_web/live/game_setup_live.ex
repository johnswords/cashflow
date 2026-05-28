defmodule CashflowWeb.GameSetupLive do
  use CashflowWeb, :live_view

  alias Cashflow.Games

  @colors ~w(blue green purple orange red yellow)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, title: "", players: blank_players(), colors: @colors, error: nil)}
  end

  @impl true
  def handle_event("save", %{"game" => params}, socket) do
    title = Map.get(params, "title", "")
    players = player_rows_from_params(Map.get(params, "players", %{}))

    attrs = %{
      "title" => title,
      "players" => players
    }

    case Games.create_game(attrs) do
      {:ok, game} ->
        {:noreply, push_navigate(socket, to: ~p"/games/#{game.id}")}

      {:error, reason} ->
        {:noreply,
         assign(socket, title: title, players: form_players(players), error: human_error(reason))}
    end
  end

  defp blank_players do
    Enum.map(0..5, &blank_player/1)
  end

  defp blank_player(index) do
    %{"name" => "", "color" => Enum.at(@colors, index, hd(@colors)), "profession" => ""}
  end

  defp player_rows_from_params(players) when is_map(players) do
    players
    |> Enum.sort_by(fn {key, _player} -> player_row_sort_key(key) end)
    |> Enum.map(fn {_key, player} -> normalize_player_params(player) end)
  end

  defp player_rows_from_params(players) when is_list(players) do
    Enum.map(players, &normalize_player_params/1)
  end

  defp player_rows_from_params(_players), do: []

  defp player_row_sort_key(key) do
    case Integer.parse(to_string(key)) do
      {index, ""} -> {0, index}
      _ -> {1, to_string(key)}
    end
  end

  defp normalize_player_params(player) when is_map(player) do
    player = Map.new(player, fn {key, value} -> {to_string(key), value || ""} end)

    %{
      "name" => Map.get(player, "name", ""),
      "color" => Map.get(player, "color", ""),
      "profession" => Map.get(player, "profession", "")
    }
  end

  defp normalize_player_params(_player), do: %{"name" => "", "color" => "", "profession" => ""}

  defp form_players(players) do
    players
    |> Enum.with_index()
    |> Enum.map(fn {player, index} -> Map.merge(blank_player(index), player) end)
    |> pad_form_players()
  end

  defp pad_form_players(players) when length(players) >= 6, do: players

  defp pad_form_players(players) do
    players ++ Enum.map(length(players)..5, &blank_player/1)
  end

  defp human_error(:not_enough_players), do: "Add at least two players."
  defp human_error(:too_many_players), do: "Use six players or fewer."
  defp human_error(:duplicate_player_names), do: "Player names must be unique."
  defp human_error(:duplicate_player_colors), do: "Player colors must be unique."
  defp human_error(%Ecto.Changeset{}), do: "Check the player details and try again."
  defp human_error(reason), do: "Could not create game: #{inspect(reason)}"

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 px-4 py-6">
      <section class="mx-auto max-w-4xl rounded-lg bg-base-100 p-4 shadow-sm sm:p-6">
        <div class="mb-5 flex items-center justify-between gap-4">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-primary">New Game</p>
            <h1 class="text-3xl font-bold">Set Up Players</h1>
          </div>
          <.button navigate={~p"/"}>Lobby</.button>
        </div>

        <p :if={@error} class="alert alert-error mb-4">{@error}</p>

        <.form for={%{}} as={:game} phx-submit="save" class="grid gap-5">
          <.input name="game[title]" label="Game title" value={@title} placeholder="Friday Cashflow" />

          <div class="grid gap-3">
            <div
              :for={{player, index} <- Enum.with_index(@players)}
              class="grid gap-3 rounded border border-base-300 p-3 md:grid-cols-[1fr_1fr_160px]"
            >
              <.input
                name={"game[players][#{index}][name]"}
                label={"Player #{index + 1}"}
                value={player["name"]}
                placeholder={if index < 2, do: "Required", else: "Optional"}
              />
              <.input
                name={"game[players][#{index}][profession]"}
                label="Profession"
                value={player["profession"]}
              />
              <.input
                name={"game[players][#{index}][color]"}
                type="select"
                label="Color"
                value={player["color"]}
                options={Enum.map(@colors, &{Phoenix.Naming.humanize(&1), &1})}
              />
            </div>
          </div>

          <div class="flex justify-end">
            <.button type="submit">Create Game</.button>
          </div>
        </.form>
      </section>
    </main>
    """
  end
end
