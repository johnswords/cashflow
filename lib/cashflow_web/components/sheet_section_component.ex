defmodule CashflowWeb.SheetSectionComponent do
  use CashflowWeb, :live_component

  alias Cashflow.Money

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg bg-base-100 p-4 shadow-sm lg:col-span-2">
      <h2 class="mb-3 text-xl font-semibold">{@title}</h2>
      <div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        <.input
          :for={{label, key, path} <- @fields}
          name={"sheet[#{key}]"}
          label={label}
          value={money_value(@draft, path)}
          disabled={@readonly}
        />
        <.input
          :if={@children?}
          name="sheet[children_count]"
          type="number"
          min="0"
          label="Children"
          value={get_in(@draft, ["expenses", "children_count"])}
          disabled={@readonly}
        />
        <.input name="sheet[notes]" label="Save note" value={@note} disabled={@readonly} />
      </div>

      <div :if={@phase == "rat_race"} class="mt-5 grid gap-5">
        <.rat_race_investments draft={@draft} readonly={@readonly} />
      </div>

      <div :if={@phase == "fast_track"} class="mt-5 grid gap-5">
        <.fast_track_details draft={@draft} readonly={@readonly} />
      </div>
    </section>
    """
  end

  attr :draft, :map, required: true
  attr :readonly, :boolean, required: true

  defp rat_race_investments(assigns) do
    ~H"""
    <section class="grid gap-3">
      <h3 class="text-lg font-semibold">Real Estate</h3>
      <div
        :for={{row, index} <- indexed_rows(@draft, ["investments", "real_estate"])}
        class="grid gap-2 rounded border border-base-300 p-3 sm:grid-cols-2 xl:grid-cols-5"
      >
        <.input
          name={investment_name("real_estate", index, "name")}
          label={"Property #{index + 1}"}
          value={text_value(row, "name")}
          disabled={@readonly}
        />
        <.input
          name={investment_name("real_estate", index, "down_payment")}
          label="Down Payment"
          value={money_value(row, ["down_payment_cents"])}
          disabled={@readonly}
        />
        <.input
          name={investment_name("real_estate", index, "cost")}
          label="Cost"
          value={money_value(row, ["cost_cents"])}
          disabled={@readonly}
        />
        <.input
          name={investment_name("real_estate", index, "mortgage")}
          label="Mortgage"
          value={money_value(row, ["mortgage_cents"])}
          disabled={@readonly}
        />
        <.input
          name={investment_name("real_estate", index, "income")}
          label="Cashflow"
          value={money_value(row, ["income_cents"])}
          disabled={@readonly}
        />
      </div>
    </section>

    <section class="grid gap-3">
      <h3 class="text-lg font-semibold">Businesses</h3>
      <div
        :for={{row, index} <- indexed_rows(@draft, ["investments", "businesses"])}
        class="grid gap-2 rounded border border-base-300 p-3 sm:grid-cols-2 xl:grid-cols-5"
      >
        <.input
          name={investment_name("businesses", index, "name")}
          label={"Business #{index + 1}"}
          value={text_value(row, "name")}
          disabled={@readonly}
        />
        <.input
          name={investment_name("businesses", index, "down_payment")}
          label="Down Payment"
          value={money_value(row, ["down_payment_cents"])}
          disabled={@readonly}
        />
        <.input
          name={investment_name("businesses", index, "cost")}
          label="Cost"
          value={money_value(row, ["cost_cents"])}
          disabled={@readonly}
        />
        <.input
          name={investment_name("businesses", index, "liability")}
          label="Liability"
          value={money_value(row, ["liability_cents"])}
          disabled={@readonly}
        />
        <.input
          name={investment_name("businesses", index, "income")}
          label="Cashflow"
          value={money_value(row, ["income_cents"])}
          disabled={@readonly}
        />
      </div>
    </section>

    <section class="grid gap-3">
      <h3 class="text-lg font-semibold">Stocks / Mutual Funds / CDs</h3>
      <div
        :for={{row, index} <- indexed_rows(@draft, ["investments", "stocks"])}
        class="grid gap-2 rounded border border-base-300 p-3 sm:grid-cols-3"
      >
        <.input
          name={investment_name("stocks", index, "name")}
          label={"Symbol #{index + 1}"}
          value={text_value(row, "name")}
          disabled={@readonly}
        />
        <.input
          name={investment_name("stocks", index, "shares")}
          type="number"
          min="0"
          label="Shares"
          value={integer_value(row, "shares")}
          disabled={@readonly}
        />
        <.input
          name={investment_name("stocks", index, "cost_per_share")}
          label="Cost / Share"
          value={money_value(row, ["cost_per_share_cents"])}
          disabled={@readonly}
        />
      </div>
    </section>
    """
  end

  attr :draft, :map, required: true
  attr :readonly, :boolean, required: true

  defp fast_track_details(assigns) do
    ~H"""
    <section class="grid gap-3 rounded border border-base-300 p-3">
      <h3 class="text-lg font-semibold">Dream</h3>
      <div class="grid gap-3 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-end">
        <.input
          name="sheet[fast_track][dream]"
          label="Dream"
          value={text_value(get_in(@draft, ["fast_track"]) || %{}, "dream")}
          disabled={@readonly}
        />
        <.input
          name="sheet[fast_track][dream_completed]"
          type="checkbox"
          label="Completed"
          checked={!!get_in(@draft, ["fast_track", "dream_completed"])}
          disabled={@readonly}
        />
      </div>
    </section>

    <section class="grid gap-3">
      <h3 class="text-lg font-semibold">Fast Track Investments</h3>
      <div
        :for={{row, index} <- indexed_rows(@draft, ["fast_track", "investments"])}
        class="grid gap-2 rounded border border-base-300 p-3 sm:grid-cols-[minmax(0,1fr)_minmax(10rem,16rem)]"
      >
        <.input
          name={fast_track_investment_name(index, "name")}
          label={"Investment #{index + 1}"}
          value={text_value(row, "name")}
          disabled={@readonly}
        />
        <.input
          name={fast_track_investment_name(index, "cashflow")}
          label="Cashflow"
          value={money_value(row, ["cashflow_cents"])}
          disabled={@readonly}
        />
      </div>
    </section>
    """
  end

  defp money_value(sheet, path), do: sheet |> get_in(path) |> Money.display()

  defp text_value(map, key), do: Map.get(map, key, "")

  defp integer_value(map, key), do: Map.get(map, key, 0)

  defp indexed_rows(sheet, path) do
    sheet
    |> get_in(path)
    |> List.wrap()
    |> Enum.with_index()
  end

  defp investment_name(kind, index, field),
    do: "sheet[investments][#{kind}][#{index}][#{field}]"

  defp fast_track_investment_name(index, field),
    do: "sheet[fast_track][investments][#{index}][#{field}]"
end
