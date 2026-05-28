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
end
