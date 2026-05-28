defmodule CashflowWeb.PlayerSheetLive do
  use CashflowWeb, :live_view

  alias Cashflow.{Calculations, Games, Money, Sheets}
  alias CashflowWeb.SheetSectionComponent
  import CashflowWeb.FormatHelpers

  @rat_race_money_fields [
    {"Salary", "salary", ["income", "salary_cents"]},
    {"Interest", "interest", ["income", "interest_cents"]},
    {"Dividends", "dividends", ["income", "dividends_cents"]},
    {"Taxes", "taxes", ["expenses", "taxes_cents"]},
    {"Mortgage Payment", "mortgage_payment", ["expenses", "mortgage_cents"]},
    {"School Loan Payment", "school_loan_payment", ["expenses", "school_loan_cents"]},
    {"Car Loan Payment", "car_loan_payment", ["expenses", "car_loan_cents"]},
    {"Credit Card Payment", "credit_card_payment", ["expenses", "credit_card_cents"]},
    {"Retail Payment", "retail_payment", ["expenses", "retail_cents"]},
    {"Other Expenses", "other", ["expenses", "other_cents"]},
    {"Miscellaneous", "miscellaneous", ["expenses", "miscellaneous_cents"]},
    {"Per Child Expense", "per_child", ["expenses", "per_child_cents"]},
    {"Savings", "savings", ["assets", "savings_cents"]},
    {"Mortgage Liability", "mortgage_liability", ["liabilities", "mortgage_cents"]},
    {"School Loan Liability", "school_loan_liability", ["liabilities", "school_loan_cents"]},
    {"Car Loan Liability", "car_loan_liability", ["liabilities", "car_loan_cents"]},
    {"Credit Card Liability", "credit_card_liability", ["liabilities", "credit_card_cents"]},
    {"Retail Liability", "retail_liability", ["liabilities", "retail_cents"]},
    {"Bank Loan Liability", "bank_loan_liability", ["liabilities", "bank_loan_cents"]}
  ]

  @fast_track_money_fields [
    {"Starting Passive Income", "starting_passive_income",
     ["fast_track", "starting_passive_income_cents"]},
    {"Cashflow Day Income", "cashflow_day_income", ["fast_track", "cashflow_day_income_cents"]},
    {"Portfolio Income", "portfolio_income", ["fast_track", "portfolio_income_cents"]},
    {"Savings", "savings", ["assets", "savings_cents"]}
  ]

  @impl true
  def mount(%{"game_id" => game_id, "player_id" => player_id} = params, _session, socket) do
    game = Games.get_game!(game_id)

    player =
      Enum.find(game.players, &(&1.id == player_id)) ||
        raise Ecto.NoResultsError, queryable: "players"

    origin_event_id = params["origin_event_id"]

    socket =
      socket
      |> assign(:game, game)
      |> assign(:player, player)
      |> assign(:draft, player.sheet_state)
      |> assign(:origin_event_id, origin_event_id)
      |> assign(:save_note, "")
      |> assign(:review, nil)
      |> assign(:error, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("review", %{"sheet" => params}, socket) do
    draft = apply_form(socket.assigns.draft, params)
    review = Sheets.diff(socket.assigns.player.sheet_state, draft)
    save_note = Map.get(params, "notes", "")

    {:noreply, assign(socket, draft: draft, review: review, save_note: save_note, error: nil)}
  end

  def handle_event("save", %{"sheet" => params}, socket) do
    draft = apply_form(socket.assigns.draft, params)
    player = socket.assigns.player
    event_type = if socket.assigns.origin_event_id, do: "correction", else: "turn"
    notes = Map.get(params, "notes") || socket.assigns.save_note

    opts = [
      event_type: event_type,
      origin_event_id: socket.assigns.origin_event_id,
      notes: notes,
      baseline_lock_version: player.lock_version
    ]

    case Games.save_player_sheet(socket.assigns.game.id, player.id, draft, opts) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sheet saved.")
         |> push_navigate(to: ~p"/games/#{socket.assigns.game.id}")}

      {:error, {:stale, _current}} ->
        {:noreply,
         assign(socket,
           draft: draft,
           error: "This sheet changed in another tab. Reload before saving."
         )}

      {:error, :completed_game} ->
        {:noreply, assign(socket, error: "Completed games are read-only.")}

      {:error, :no_changes} ->
        {:noreply, assign(socket, draft: draft, error: "No changes to save.")}

      {:error, reason} ->
        {:noreply, assign(socket, draft: draft, error: "Could not save: #{inspect(reason)}")}
    end
  end

  defp apply_form(sheet, params) do
    sheet =
      Enum.reduce(sheet_fields(sheet), sheet, fn {_label, key, path}, sheet ->
        value = Map.get(params, key, get_in(sheet, path))

        case Sheets.put_money(sheet, path, value) do
          {:ok, sheet} -> sheet
          {:error, _} -> sheet
        end
      end)

    if children_field?(sheet) do
      apply_children_count(sheet, params)
    else
      sheet
    end
  end

  defp apply_children_count(sheet, params) do
    children =
      params
      |> Map.get("children_count", get_in(sheet, ["expenses", "children_count"]) || 0)
      |> parse_non_negative_integer()

    put_in(sheet, ["expenses", "children_count"], children)
  end

  defp sheet_fields(%{"phase" => "fast_track"}), do: @fast_track_money_fields
  defp sheet_fields(_sheet), do: @rat_race_money_fields

  defp children_field?(%{"phase" => "fast_track"}), do: false
  defp children_field?(_sheet), do: true

  defp sheet_title(%{"phase" => "fast_track"}), do: "Fast Track Sheet"
  defp sheet_title(_sheet), do: "Rat Race Sheet"

  defp parse_non_negative_integer(value) when is_integer(value), do: max(value, 0)

  defp parse_non_negative_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> max(integer, 0)
      _ -> 0
    end
  end

  defp money_value(sheet, path), do: sheet |> get_in(path) |> Money.display()

  defp summary(sheet), do: Calculations.summary(sheet)

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 px-4 py-6">
      <section class="mx-auto grid max-w-7xl gap-5">
        <header class="flex flex-col gap-4 rounded-lg bg-base-100 p-4 shadow-sm md:flex-row md:items-center md:justify-between">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-primary">
              {@game.title} · {phase_label(@player.phase)}
            </p>
            <h1 class="text-3xl font-bold">{@player.name}</h1>
          </div>
          <.button navigate={~p"/games/#{@game.id}"}>Dashboard</.button>
        </header>

        <p :if={@error} class="alert alert-error">{@error}</p>

        <% readonly = @game.status == "completed" %>
        <% summary = summary(@draft) %>
        <% sheet_fields = sheet_fields(@draft) %>
        <% children_field? = children_field?(@draft) %>

        <section class="grid gap-3 rounded-lg bg-base-100 p-4 shadow-sm sm:grid-cols-3 lg:grid-cols-6">
          <div class="rounded bg-base-200 p-2">
            <p class="text-xs uppercase">Cash</p>
            <strong>{money(summary.cash_cents)}</strong>
          </div>
          <div class="rounded bg-base-200 p-2">
            <p class="text-xs uppercase">Passive</p>
            <strong>{money(summary.passive_income_cents)}</strong>
          </div>
          <div class="rounded bg-base-200 p-2">
            <p class="text-xs uppercase">Income</p>
            <strong>{money(summary.total_income_cents)}</strong>
          </div>
          <div class="rounded bg-base-200 p-2">
            <p class="text-xs uppercase">Expenses</p>
            <strong>{money(summary.total_expenses_cents)}</strong>
          </div>
          <div class="rounded bg-base-200 p-2">
            <p class="text-xs uppercase">Cashflow</p>
            <strong>{money(summary.cashflow_cents)}</strong>
          </div>
          <div class="rounded bg-base-200 p-2">
            <p class="text-xs uppercase">Children</p>
            <strong>{summary.children_count}</strong>
          </div>
        </section>

        <.form for={%{}} as={:sheet} phx-submit="review" class="grid gap-5">
          <div class="grid gap-4 lg:grid-cols-3">
            <.live_component
              module={SheetSectionComponent}
              id="player-sheet-section"
              title={sheet_title(@draft)}
              fields={sheet_fields}
              draft={@draft}
              note={@save_note}
              readonly={readonly}
              children?={children_field?}
            />

            <aside class="rounded-lg bg-base-100 p-4 shadow-sm">
              <h2 class="mb-3 text-xl font-semibold">Diff Review</h2>
              <p :if={!@review} class="text-sm text-base-content/70">Review changes before saving.</p>
              <ul :if={@review} class="grid max-h-96 gap-2 overflow-auto text-sm">
                <li :for={change <- @review["changes"]} class="rounded border border-base-300 p-2">
                  <strong>{change["path"]}</strong>
                  <p>{inspect(change["before"])} → {inspect(change["after"])}</p>
                </li>
                <li :if={@review["changes"] == []} class="rounded border border-base-300 p-2">
                  No changes.
                </li>
              </ul>
            </aside>
          </div>

          <div class="sticky bottom-0 flex justify-end gap-2 rounded-lg bg-base-100 p-3 shadow">
            <.button navigate={~p"/games/#{@game.id}"}>Cancel</.button>
            <.button :if={!readonly} type="submit">Review</.button>
          </div>
        </.form>

        <.form
          :if={@review && @review["changes"] != [] && !readonly}
          for={%{}}
          as={:sheet}
          phx-submit="save"
          class="flex justify-end"
        >
          <input
            :for={{_label, key, path} <- sheet_fields}
            type="hidden"
            name={"sheet[#{key}]"}
            value={money_value(@draft, path)}
          />
          <input
            :if={children_field?}
            type="hidden"
            name="sheet[children_count]"
            value={get_in(@draft, ["expenses", "children_count"])}
          />
          <input type="hidden" name="sheet[notes]" value={@save_note} />
          <.button type="submit">Save Reviewed Changes</.button>
        </.form>
      </section>
    </main>
    """
  end
end
