defmodule Cashflow.CalculationsTest do
  use ExUnit.Case, async: true

  alias Cashflow.{Calculations, Sheets}

  test "calculates representative rat-race summary" do
    sheet =
      Sheets.default_sheet(%{
        "income" => %{
          "salary_cents" => 300_000,
          "interest_cents" => 5_000,
          "dividends_cents" => 2_500
        },
        "investments" => %{
          "real_estate" => [
            %{"income_cents" => 20_000},
            %{"income_cents" => 15_000}
          ],
          "businesses" => [%{"income_cents" => 40_000}]
        },
        "expenses" => %{
          "taxes_cents" => 60_000,
          "mortgage_cents" => 70_000,
          "school_loan_cents" => 10_000,
          "car_loan_cents" => 20_000,
          "credit_card_cents" => 5_000,
          "retail_cents" => 2_500,
          "other_cents" => 30_000,
          "miscellaneous_cents" => 7_500,
          "children_count" => 2,
          "per_child_cents" => 15_000
        },
        "liabilities" => %{"bank_loan_cents" => 125_000}
      })

    summary = Calculations.summary(sheet)

    assert summary.passive_income_cents == 82_500
    assert summary.total_income_cents == 382_500
    assert Calculations.bank_loan_payment_cents(sheet) == 12_500
    assert Calculations.child_expenses_cents(sheet) == 30_000
    assert summary.total_expenses_cents == 247_500
    assert summary.cashflow_cents == 135_000
    refute summary.eligible_for_fast_track
  end

  test "fast-track eligibility uses strict greater-than boundary" do
    at_boundary =
      Sheets.default_sheet(%{
        "income" => %{"interest_cents" => 247_500},
        "expenses" => %{"taxes_cents" => 247_500}
      })

    over_boundary =
      Sheets.default_sheet(%{
        "income" => %{"interest_cents" => 247_600},
        "expenses" => %{"taxes_cents" => 247_500}
      })

    refute Calculations.eligible_for_fast_track?(at_boundary)
    assert Calculations.eligible_for_fast_track?(over_boundary)
  end

  test "fast-track beginning cashflow day income follows legacy round-to-thousand rule" do
    assert Calculations.beginning_cashflow_day_income_cents(
             Sheets.default_sheet(%{"income" => %{"interest_cents" => 247_600}})
           ) == 20_000_000

    assert Calculations.beginning_cashflow_day_income_cents(
             Sheets.default_sheet(%{"income" => %{"interest_cents" => 250_000}})
           ) == 30_000_000
  end

  test "rounding calculations stay in integer space for large values" do
    sheet =
      Sheets.default_sheet(%{
        "income" => %{"interest_cents" => 9_007_199_254_750_000},
        "liabilities" => %{"bank_loan_cents" => 9_007_199_254_740_995}
      })

    assert Calculations.bank_loan_payment_cents(sheet) == 900_719_925_474_100
    assert Calculations.beginning_cashflow_day_income_cents(sheet) == 900_719_925_480_000_000
  end
end
