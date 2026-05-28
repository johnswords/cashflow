defmodule Cashflow.Calculations do
  @moduledoc """
  Cashflow calculation engine.
  """

  alias Cashflow.Sheets

  def summary(sheet) do
    sheet = Sheets.normalize!(sheet)

    %{
      cash_cents: cash_cents(sheet),
      salary_cents: salary_cents(sheet),
      passive_income_cents: passive_income_cents(sheet),
      total_income_cents: total_income_cents(sheet),
      total_expenses_cents: total_expenses_cents(sheet),
      cashflow_cents: cashflow_cents(sheet),
      children_count: children_count(sheet),
      phase: Map.fetch!(sheet, "phase"),
      eligible_for_fast_track: eligible_for_fast_track?(sheet)
    }
  end

  def salary_cents(sheet), do: get_cents(sheet, ["income", "salary_cents"])

  def passive_income_cents(%{"phase" => "fast_track"} = sheet) do
    get_cents(sheet, ["fast_track", "starting_passive_income_cents"]) +
      get_cents(sheet, ["fast_track", "portfolio_income_cents"])
  end

  def passive_income_cents(sheet) do
    sheet = Sheets.normalize!(sheet)

    get_cents(sheet, ["income", "interest_cents"]) +
      get_cents(sheet, ["income", "dividends_cents"]) +
      investment_income(sheet, ["investments", "real_estate"]) +
      investment_income(sheet, ["investments", "businesses"])
  end

  def total_income_cents(%{"phase" => "fast_track"} = sheet) do
    get_cents(sheet, ["fast_track", "cashflow_day_income_cents"]) + passive_income_cents(sheet)
  end

  def total_income_cents(sheet), do: salary_cents(sheet) + passive_income_cents(sheet)

  def child_expenses_cents(sheet) do
    children_count(sheet) * get_cents(sheet, ["expenses", "per_child_cents"])
  end

  def bank_loan_payment_cents(sheet),
    do: round_div(get_cents(sheet, ["liabilities", "bank_loan_cents"]), 10)

  def total_expenses_cents(%{"phase" => "fast_track"}), do: 0

  def total_expenses_cents(sheet) do
    sheet = Sheets.normalize!(sheet)

    Enum.sum([
      get_cents(sheet, ["expenses", "taxes_cents"]),
      get_cents(sheet, ["expenses", "mortgage_cents"]),
      get_cents(sheet, ["expenses", "school_loan_cents"]),
      get_cents(sheet, ["expenses", "car_loan_cents"]),
      get_cents(sheet, ["expenses", "credit_card_cents"]),
      get_cents(sheet, ["expenses", "retail_cents"]),
      get_cents(sheet, ["expenses", "other_cents"]),
      get_cents(sheet, ["expenses", "miscellaneous_cents"]),
      child_expenses_cents(sheet),
      bank_loan_payment_cents(sheet)
    ])
  end

  def cashflow_cents(sheet), do: total_income_cents(sheet) - total_expenses_cents(sheet)

  def children_count(sheet), do: get_in(sheet, ["expenses", "children_count"]) || 0

  def cash_cents(sheet), do: get_cents(sheet, ["assets", "savings_cents"])

  def eligible_for_fast_track?(sheet),
    do: passive_income_cents(sheet) > total_expenses_cents(sheet)

  def beginning_cashflow_day_income_cents(sheet) do
    sheet
    |> passive_income_cents()
    |> round_div(100_000)
    |> Kernel.*(10_000_000)
  end

  defp round_div(value, divisor) when is_integer(value) and value >= 0 do
    div(value + div(divisor, 2), divisor)
  end

  defp round_div(value, divisor) when is_integer(value) do
    -round_div(abs(value), divisor)
  end

  defp investment_income(sheet, path) do
    sheet
    |> get_in(path)
    |> List.wrap()
    |> Enum.reduce(0, fn item, total -> total + get_cents(item, ["income_cents"]) end)
  end

  defp get_cents(map, path), do: get_in(map, path) || 0
end
