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

    player = find_player!(game, player_id)

    origin_event_id = params["origin_event_id"]

    origin_event = load_origin_event(origin_event_id, game, player)
    draft_baseline = draft_baseline(origin_event, player)

    socket =
      socket
      |> assign(:game, game)
      |> assign(:player, player)
      |> assign(:draft_baseline, draft_baseline)
      |> assign(:draft, draft_baseline)
      |> assign(:origin_event_id, origin_event_id)
      |> assign(:origin_event, origin_event)
      |> assign(:save_note, "")
      |> assign(:review, nil)
      |> assign(:parse_errors, %{})
      |> assign(:conflict, nil)
      |> assign(:error, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("change", %{"sheet" => params}, socket) do
    {draft, parse_errors} = apply_form(socket.assigns.draft, params)
    save_note = Map.get(params, "notes", socket.assigns.save_note)

    {:noreply,
     assign(socket,
       draft: draft,
       save_note: save_note,
       review: nil,
       parse_errors: parse_errors,
       conflict: nil,
       error: nil
     )}
  end

  def handle_event("review", %{"sheet" => params}, socket) do
    {draft, parse_errors} = apply_form(socket.assigns.draft, params)
    save_note = Map.get(params, "notes", "")

    if map_size(parse_errors) == 0 do
      review = Sheets.diff(socket.assigns.draft_baseline, draft)

      {:noreply,
       assign(socket,
         draft: draft,
         review: review,
         save_note: save_note,
         parse_errors: %{},
         conflict: nil,
         error: nil
       )}
    else
      {:noreply,
       assign(socket,
         draft: draft,
         review: nil,
         save_note: save_note,
         parse_errors: parse_errors,
         conflict: nil,
         error: "Fix the highlighted fields before reviewing."
       )}
    end
  end

  def handle_event("save", params, socket) do
    sheet_params = Map.get(params, "sheet", %{})
    form_draft = socket.assigns.draft
    draft = save_draft(socket.assigns)
    player = socket.assigns.player
    event_type = if socket.assigns.origin_event_id, do: "correction", else: "turn"
    notes = Map.get(sheet_params, "notes") || socket.assigns.save_note

    opts = [
      event_type: event_type,
      origin_event_id: socket.assigns.origin_event_id,
      notes: notes,
      baseline_lock_version: player.lock_version
    ]

    cond do
      map_size(socket.assigns.parse_errors) > 0 ->
        {:noreply, assign(socket, error: "Fix the highlighted fields before saving.")}

      is_nil(socket.assigns.review) ->
        {:noreply, assign(socket, error: "Review the current changes before saving.")}

      true ->
        save_reviewed_sheet(socket, draft, opts, form_draft)
    end
  end

  def handle_event("reload_current", _params, socket) do
    {:noreply,
     socket
     |> reload_game_and_player()
     |> then(fn socket ->
       assign(socket,
         draft_baseline: socket.assigns.player.sheet_state,
         draft: socket.assigns.player.sheet_state,
         review: nil,
         parse_errors: %{},
         conflict: nil,
         error: nil
       )
     end)}
  end

  defp save_reviewed_sheet(socket, draft, opts, form_draft) do
    player = socket.assigns.player

    case Games.save_player_sheet(socket.assigns.game.id, player.id, draft, opts) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sheet saved.")
         |> push_navigate(to: ~p"/games/#{socket.assigns.game.id}")}

      {:error, {:stale, _current}} ->
        {:noreply,
         socket
         |> reload_game_and_player()
         |> assign(
           draft: form_draft,
           review: nil,
           conflict: %{
             kind: :stale,
             title: "Sheet changed in another tab",
             message:
               "Reload the current sheet before saving. Your draft has not overwritten the latest version."
           },
           error: nil
         )}

      {:error, :completed_game} ->
        {:noreply,
         socket
         |> reload_game_and_player()
         |> then(fn socket ->
           assign(socket,
             draft_baseline: socket.assigns.player.sheet_state,
             draft: socket.assigns.player.sheet_state,
             review: nil,
             conflict: %{
               kind: :completed,
               title: "Game completed in another tab",
               message: "This sheet is now read-only. The completed state has been loaded."
             },
             error: nil
           )
         end)}

      {:error, :no_changes} ->
        {:noreply, assign(socket, draft: form_draft, review: nil, error: "No changes to save.")}

      {:error, reason} ->
        {:noreply, assign(socket, draft: form_draft, error: "Could not save: #{inspect(reason)}")}
    end
  end

  defp apply_form(sheet, params) do
    {sheet, errors} =
      Enum.reduce(sheet_fields(sheet), {sheet, %{}}, fn {label, key, path}, {sheet, errors} ->
        value = Map.get(params, key, get_in(sheet, path))
        put_money_field(sheet, errors, key, label, path, value)
      end)

    {sheet, errors} =
      if children_field?(sheet),
        do: apply_children_count(sheet, params, errors),
        else: {sheet, errors}

    apply_phase_form(sheet, params, errors)
  end

  defp apply_children_count(sheet, params, errors) do
    value = Map.get(params, "children_count", get_in(sheet, ["expenses", "children_count"]) || 0)

    case parse_non_negative_integer(value) do
      {:ok, children} ->
        {put_in(sheet, ["expenses", "children_count"], children), errors}

      :error ->
        {sheet, add_error(errors, "children_count", "Children must be zero or more.")}
    end
  end

  defp apply_phase_form(%{"phase" => "fast_track"} = sheet, params, errors) do
    fast_track_params = Map.get(params, "fast_track", %{})
    investment_params = Map.get(fast_track_params, "investments", %{})

    fast_track =
      sheet
      |> get_in(["fast_track"])
      |> Map.put(
        "dream",
        text_param(fast_track_params, "dream", get_in(sheet, ["fast_track", "dream"]))
      )
      |> Map.put(
        "dream_completed",
        boolean_param(fast_track_params, "dream_completed")
      )

    {investments, errors} =
      update_rows(
        get_in(sheet, ["fast_track", "investments"]),
        investment_params,
        errors,
        fn row, row_params, index, errors ->
          row
          |> put_text_param(row_params, "name")
          |> put_money_param(
            errors,
            fast_track_error_key(index, "cashflow"),
            "Investment #{index + 1} Cashflow",
            row_params,
            "cashflow_cents",
            "cashflow"
          )
        end
      )

    {put_in(sheet, ["fast_track"], Map.put(fast_track, "investments", investments)), errors}
  end

  defp apply_phase_form(sheet, params, errors) do
    investment_params = Map.get(params, "investments", %{})

    {real_estate, errors} =
      update_rows(
        get_in(sheet, ["investments", "real_estate"]),
        Map.get(investment_params, "real_estate", %{}),
        errors,
        fn row, row_params, index, errors ->
          row
          |> put_text_param(row_params, "name")
          |> put_money_param(
            errors,
            investment_error_key("real_estate", index, "down_payment"),
            "Property #{index + 1} Down Payment",
            row_params,
            "down_payment_cents",
            "down_payment"
          )
          |> put_money_param(
            errors,
            investment_error_key("real_estate", index, "cost"),
            "Property #{index + 1} Cost",
            row_params,
            "cost_cents",
            "cost"
          )
          |> put_money_param(
            errors,
            investment_error_key("real_estate", index, "mortgage"),
            "Property #{index + 1} Mortgage",
            row_params,
            "mortgage_cents",
            "mortgage"
          )
          |> put_money_param(
            errors,
            investment_error_key("real_estate", index, "income"),
            "Property #{index + 1} Cashflow",
            row_params,
            "income_cents",
            "income"
          )
        end
      )

    {businesses, errors} =
      update_rows(
        get_in(sheet, ["investments", "businesses"]),
        Map.get(investment_params, "businesses", %{}),
        errors,
        fn row, row_params, index, errors ->
          row
          |> put_text_param(row_params, "name")
          |> put_money_param(
            errors,
            investment_error_key("businesses", index, "down_payment"),
            "Business #{index + 1} Down Payment",
            row_params,
            "down_payment_cents",
            "down_payment"
          )
          |> put_money_param(
            errors,
            investment_error_key("businesses", index, "cost"),
            "Business #{index + 1} Cost",
            row_params,
            "cost_cents",
            "cost"
          )
          |> put_money_param(
            errors,
            investment_error_key("businesses", index, "liability"),
            "Business #{index + 1} Liability",
            row_params,
            "liability_cents",
            "liability"
          )
          |> put_money_param(
            errors,
            investment_error_key("businesses", index, "income"),
            "Business #{index + 1} Cashflow",
            row_params,
            "income_cents",
            "income"
          )
        end
      )

    {stocks, errors} =
      update_rows(
        get_in(sheet, ["investments", "stocks"]),
        Map.get(investment_params, "stocks", %{}),
        errors,
        fn row, row_params, index, errors ->
          row
          |> put_text_param(row_params, "name")
          |> put_integer_param(
            errors,
            investment_error_key("stocks", index, "shares"),
            "Stock #{index + 1} Shares",
            row_params,
            "shares"
          )
          |> put_money_param(
            errors,
            investment_error_key("stocks", index, "cost_per_share"),
            "Stock #{index + 1} Cost / Share",
            row_params,
            "cost_per_share_cents",
            "cost_per_share"
          )
        end
      )

    sheet =
      sheet
      |> put_in(["investments", "real_estate"], real_estate)
      |> put_in(["investments", "businesses"], businesses)
      |> put_in(["investments", "stocks"], stocks)

    {sheet, errors}
  end

  defp update_rows(rows, params, errors, update_fun) do
    rows
    |> List.wrap()
    |> Enum.with_index()
    |> Enum.reduce({[], errors}, fn {row, index}, {rows, errors} ->
      row_params = Map.get(params, Integer.to_string(index), %{})
      {row, errors} = update_fun.(row, row_params, index, errors)
      {[row | rows], errors}
    end)
    |> then(fn {rows, errors} -> {Enum.reverse(rows), errors} end)
  end

  defp put_text_param(row, params, key) do
    Map.put(row, key, text_param(params, key, Map.get(row, key, "")))
  end

  defp put_money_param(row_state, errors, error_key, label, params, key, param_key) do
    {row, errors} = row_with_errors(row_state, errors)
    current = Map.get(row, key, 0)
    value = Map.get(params, param_key, current)

    case Money.parse_cents(value) do
      {:ok, cents} -> {Map.put(row, key, cents), errors}
      {:error, _} -> {row, add_error(errors, error_key, "#{label} must be a money amount.")}
    end
  end

  defp put_integer_param(row_state, errors, error_key, label, params, key) do
    {row, errors} = row_with_errors(row_state, errors)

    case parse_non_negative_integer(Map.get(params, key, Map.get(row, key, 0))) do
      {:ok, integer} -> {Map.put(row, key, integer), errors}
      :error -> {row, add_error(errors, error_key, "#{label} must be zero or more.")}
    end
  end

  defp row_with_errors({row, errors}, _fallback_errors), do: row_with_errors(row, errors)
  defp row_with_errors(row, errors), do: {row, errors}

  defp put_money_field(sheet, errors, error_key, label, path, value) do
    case Money.parse_cents(value) do
      {:ok, cents} -> {put_in(sheet, path, cents), errors}
      {:error, _} -> {sheet, add_error(errors, error_key, "#{label} must be a money amount.")}
    end
  end

  defp text_param(params, key, current) do
    params
    |> Map.get(key, current || "")
    |> to_string()
    |> String.trim()
  end

  defp boolean_param(params, key) do
    case Map.fetch(params, key) do
      {:ok, value} -> truthy?(value)
      :error -> false
    end
  end

  defp truthy?(value) when is_list(value), do: value |> List.last() |> truthy?()
  defp truthy?(value), do: value in [true, "true", "1", 1, "on"]

  defp sheet_fields(%{"phase" => "fast_track"}), do: @fast_track_money_fields
  defp sheet_fields(_sheet), do: @rat_race_money_fields

  defp children_field?(%{"phase" => "fast_track"}), do: false
  defp children_field?(_sheet), do: true

  defp sheet_title(%{"phase" => "fast_track"}), do: "Fast Track Sheet"
  defp sheet_title(_sheet), do: "Rat Race Sheet"

  defp add_error(errors, key, message), do: Map.update(errors, key, [message], &[message | &1])

  defp investment_error_key(kind, index, field),
    do: "investments.#{kind}.#{index}.#{field}"

  defp fast_track_error_key(index, field), do: "fast_track.investments.#{index}.#{field}"

  defp parse_non_negative_integer(value) when is_integer(value), do: {:ok, max(value, 0)}

  defp parse_non_negative_integer(value) when is_binary(value) do
    value = String.trim(value)

    if value == "" do
      {:ok, 0}
    else
      case Integer.parse(value) do
        {integer, ""} when integer >= 0 -> {:ok, integer}
        _ -> :error
      end
    end
  end

  defp parse_non_negative_integer(_value), do: :error

  defp summary(sheet), do: Calculations.summary(sheet)

  defp parse_error_messages(errors), do: errors |> Map.values() |> List.flatten()

  defp reload_game_and_player(socket) do
    game = Games.get_game!(socket.assigns.game.id)
    player = find_player!(game, socket.assigns.player.id)

    assign(socket, game: game, player: player)
  end

  defp find_player!(game, player_id) do
    Enum.find(game.players, &(&1.id == player_id)) ||
      raise Ecto.NoResultsError, queryable: "players"
  end

  defp load_origin_event(nil, _game, _player), do: nil

  defp load_origin_event(origin_event_id, game, player) do
    event = Games.get_audit_event!(game.id, origin_event_id)

    if event.player_id == player.id do
      event
    else
      raise Ecto.NoResultsError, queryable: "audit_events"
    end
  end

  defp draft_baseline(nil, player), do: player.sheet_state

  defp draft_baseline(origin_event, player) do
    case Sheets.normalize(origin_event.after_snapshot || %{}) do
      {:ok, snapshot} -> snapshot
      {:error, _} -> player.sheet_state
    end
  end

  defp save_draft(%{origin_event_id: nil, draft: draft}), do: draft

  defp save_draft(%{
         draft_baseline: %{"phase" => phase} = baseline,
         draft: draft,
         player: %{sheet_state: %{"phase" => phase} = current_sheet}
       }) do
    baseline
    |> Sheets.diff(draft)
    |> Map.fetch!("changes")
    |> Enum.reduce(current_sheet, fn %{"path" => path, "after" => value}, sheet ->
      put_sheet_value(sheet, String.split(path, "."), value)
    end)
  end

  defp save_draft(%{draft: draft}), do: draft

  defp put_sheet_value(%{} = sheet, [key], value), do: Map.put(sheet, key, value)

  defp put_sheet_value(%{} = sheet, [key | rest], value) do
    Map.update!(sheet, key, &put_sheet_value(&1, rest, value))
  end

  defp put_sheet_value(rows, [index | rest], value) when is_list(rows) do
    index = String.to_integer(index)
    List.update_at(rows, index, &put_sheet_value(&1, rest, value))
  end

  defp field_label(path), do: Sheets.field_label(path)

  defp event_label(event_type), do: Phoenix.Naming.humanize(event_type || "")

  defp event_time(nil), do: ""
  defp event_time(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp change_value(%{"path" => path} = change, key) do
    path
    |> format_change_value(Map.get(change, key))
  end

  defp format_change_value(path, value) when is_integer(value) do
    if String.ends_with?(path, "_cents"), do: Money.display(value), else: Integer.to_string(value)
  end

  defp format_change_value(_path, true), do: "Yes"
  defp format_change_value(_path, false), do: "No"
  defp format_change_value(_path, nil), do: "Empty"
  defp format_change_value(_path, value) when is_binary(value) and value == "", do: "Empty"
  defp format_change_value(_path, value) when is_binary(value), do: value
  defp format_change_value(_path, value), do: inspect(value)

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

        <section :if={@conflict} class="rounded-lg border border-warning/30 bg-warning/10 p-4">
          <p class="text-sm font-semibold uppercase tracking-wide text-warning">Conflict</p>
          <h2 class="text-xl font-semibold">{@conflict.title}</h2>
          <p class="mt-1 text-sm text-base-content/70">{@conflict.message}</p>
          <div class="mt-3 flex flex-wrap gap-2">
            <.button type="button" phx-click="reload_current">Reload Current Sheet</.button>
            <.button navigate={~p"/games/#{@game.id}"}>Dashboard</.button>
          </div>
        </section>

        <section :if={@origin_event} class="rounded-lg border border-info/30 bg-info/10 p-4">
          <p class="text-sm font-semibold uppercase tracking-wide text-info">Correction Draft</p>
          <h2 class="text-xl font-semibold">
            {event_label(@origin_event.event_type)} from {event_time(@origin_event.inserted_at)}
          </h2>
          <p class="mt-1 text-sm text-base-content/70">
            Origin: {@origin_event.player && @origin_event.player.name}. Confirming this save will
            write a correction audit event without changing the original event.
          </p>
          <p :if={@origin_event.notes} class="mt-2 text-sm">
            Original note: {@origin_event.notes}
          </p>
          <div class="mt-3 flex flex-wrap gap-2">
            <span
              :for={path <- @origin_event.field_paths_data["paths"] || []}
              class="badge badge-info badge-outline"
              title={path}
            >
              {field_label(path)}
            </span>
          </div>
        </section>

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

        <.form
          for={%{}}
          as={:sheet}
          phx-change="change"
          phx-submit="review"
          class="grid gap-5"
        >
          <div class="grid gap-4 lg:grid-cols-3">
            <.live_component
              module={SheetSectionComponent}
              id="player-sheet-section"
              title={sheet_title(@draft)}
              fields={sheet_fields}
              draft={@draft}
              note={@save_note}
              phase={@draft["phase"]}
              readonly={readonly}
              children?={children_field?}
              errors={@parse_errors}
            />

            <aside class="order-first rounded-lg bg-base-100 p-4 shadow-sm lg:order-none">
              <h2 class="mb-3 text-xl font-semibold">Diff Review</h2>
              <p :if={!@review} class="text-sm text-base-content/70">Review changes before saving.</p>
              <ul :if={map_size(@parse_errors) > 0} class="mt-3 grid gap-2 text-sm text-error">
                <li :for={message <- parse_error_messages(@parse_errors)}>{message}</li>
              </ul>
              <ul :if={@review} class="grid max-h-96 gap-2 overflow-auto text-sm">
                <li :for={change <- @review["changes"]} class="rounded border border-base-300 p-2">
                  <strong>{field_label(change["path"])}</strong>
                  <p class="text-xs text-base-content/60">{change["path"]}</p>
                  <p>{change_value(change, "before")} → {change_value(change, "after")}</p>
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
            <.button
              :if={@review && @review["changes"] != [] && !readonly}
              type="button"
              phx-click="save"
            >
              Save Reviewed Changes
            </.button>
          </div>
        </.form>
      </section>
    </main>
    """
  end
end
