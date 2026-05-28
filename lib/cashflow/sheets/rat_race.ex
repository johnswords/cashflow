defmodule Cashflow.Sheets.RatRace do
  @moduledoc """
  Version 1 Rat Race sheet shape.
  """

  defstruct schema_version: 1,
            phase: "rat_race",
            meta: %{"profession" => "", "auditor" => "", "notes" => ""},
            income: %{
              "salary_cents" => 0,
              "interest_cents" => 0,
              "dividends_cents" => 0
            },
            expenses: %{
              "taxes_cents" => 0,
              "mortgage_cents" => 0,
              "school_loan_cents" => 0,
              "car_loan_cents" => 0,
              "credit_card_cents" => 0,
              "retail_cents" => 0,
              "other_cents" => 0,
              "miscellaneous_cents" => 0,
              "children_count" => 0,
              "per_child_cents" => 0
            },
            assets: %{"savings_cents" => 0},
            liabilities: %{
              "mortgage_cents" => 0,
              "school_loan_cents" => 0,
              "car_loan_cents" => 0,
              "credit_card_cents" => 0,
              "retail_cents" => 0,
              "bank_loan_cents" => 0
            },
            investments: %{
              "real_estate" =>
                List.duplicate(
                  %{
                    "name" => "",
                    "down_payment_cents" => 0,
                    "cost_cents" => 0,
                    "mortgage_cents" => 0,
                    "income_cents" => 0
                  },
                  4
                ),
              "businesses" =>
                List.duplicate(
                  %{
                    "name" => "",
                    "down_payment_cents" => 0,
                    "cost_cents" => 0,
                    "liability_cents" => 0,
                    "income_cents" => 0
                  },
                  2
                ),
              "stocks" =>
                List.duplicate(
                  %{
                    "name" => "",
                    "shares" => 0,
                    "cost_per_share_cents" => 0
                  },
                  2
                )
            },
            fast_track: %{
              "dream" => "",
              "starting_passive_income_cents" => 0,
              "cashflow_day_income_cents" => 0,
              "portfolio_income_cents" => 0,
              "dream_completed" => false,
              "investments" => List.duplicate(%{"name" => "", "cashflow_cents" => 0}, 12)
            }

  def new(attrs \\ %{}) do
    __MODULE__
    |> struct!()
    |> Map.from_struct()
    |> stringify_keys()
    |> deep_merge(stringify_keys(attrs))
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(value) when is_list(value), do: Enum.map(value, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      deep_merge(left_value, right_value)
    end)
  end

  defp deep_merge(_left, right), do: right
end
