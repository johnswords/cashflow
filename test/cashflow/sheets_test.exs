defmodule Cashflow.SheetsTest do
  use ExUnit.Case, async: true

  alias Cashflow.{Calculations, Sheets}

  test "default sheet preserves legacy gameplay inventory" do
    sheet = Sheets.default_sheet()

    assert sheet["schema_version"] == 1
    assert sheet["phase"] == "rat_race"
    assert sheet["expenses"]["children_count"] == 0
    assert length(sheet["investments"]["real_estate"]) == 4
    assert length(sheet["investments"]["businesses"]) == 2
    assert length(sheet["investments"]["stocks"]) == 2
    assert length(sheet["fast_track"]["investments"]) == 12
  end

  test "default sheet summary is all zero and not fast-track eligible" do
    summary = Calculations.summary(Sheets.default_sheet())

    assert summary.cash_cents == 0
    assert summary.salary_cents == 0
    assert summary.passive_income_cents == 0
    assert summary.total_income_cents == 0
    assert summary.total_expenses_cents == 0
    assert summary.cashflow_cents == 0
    refute summary.eligible_for_fast_track
  end

  test "normalizes string money values to cents" do
    assert {:ok, sheet} =
             Sheets.normalize(%{
               "income" => %{"salary_cents" => "$3,000.50"},
               "assets" => %{"savings_cents" => "-25"}
             })

    assert sheet["income"]["salary_cents"] == 300_050
    assert sheet["assets"]["savings_cents"] == -2_500
  end

  test "normalizes nested rat-race investment rows" do
    assert {:ok, sheet} =
             Sheets.normalize(%{
               "investments" => %{
                 "real_estate" => %{
                   "0" => %{
                     "name" => " Duplex ",
                     "down_payment_cents" => "$5,000",
                     "cost_cents" => "$60,000",
                     "mortgage_cents" => "$55,000",
                     "income_cents" => "$250"
                   }
                 },
                 "businesses" => %{
                   "0" => %{"name" => "Car Wash", "income_cents" => "$400.25"}
                 },
                 "stocks" => %{
                   "0" => %{"name" => "OK4U", "shares" => "12", "cost_per_share_cents" => "$10"}
                 }
               }
             })

    assert length(sheet["investments"]["real_estate"]) == 4
    assert length(sheet["investments"]["businesses"]) == 2
    assert length(sheet["investments"]["stocks"]) == 2
    assert get_in(sheet, ["investments", "real_estate", Access.at(0), "name"]) == "Duplex"
    assert get_in(sheet, ["investments", "real_estate", Access.at(0), "income_cents"]) == 25_000
    assert get_in(sheet, ["investments", "businesses", Access.at(0), "income_cents"]) == 40_025
    assert get_in(sheet, ["investments", "stocks", Access.at(0), "shares"]) == 12
    assert Calculations.passive_income_cents(sheet) == 65_025
  end

  test "normalizes fast-track dream and investment rows" do
    assert {:ok, sheet} =
             Sheets.normalize(%{
               "phase" => "fast_track",
               "fast_track" => %{
                 "dream" => "  Island school  ",
                 "dream_completed" => "true",
                 "portfolio_income_cents" => "$800",
                 "investments" => %{
                   "0" => %{"name" => "Apartment Syndicate", "cashflow_cents" => "$1,200"}
                 }
               }
             })

    assert get_in(sheet, ["fast_track", "dream"]) == "Island school"
    assert get_in(sheet, ["fast_track", "dream_completed"])
    assert length(get_in(sheet, ["fast_track", "investments"])) == 12

    assert get_in(sheet, ["fast_track", "investments", Access.at(0), "name"]) ==
             "Apartment Syndicate"

    assert get_in(sheet, ["fast_track", "investments", Access.at(0), "cashflow_cents"]) ==
             120_000

    assert get_in(sheet, ["fast_track", "portfolio_income_cents"]) == 80_000
  end
end
