defmodule CashflowWeb.SheetSectionComponent do
  use CashflowWeb, :live_component

  alias Cashflow.Money

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg bg-base-100 p-4 shadow-sm">
      <h2 class="mb-3 text-xl font-semibold">{@title}</h2>
      <div class="grid gap-3 sm:grid-cols-2">
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
    </section>
    """
  end

  defp money_value(sheet, path), do: sheet |> get_in(path) |> Money.display()
end
