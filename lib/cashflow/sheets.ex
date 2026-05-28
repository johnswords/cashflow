defmodule Cashflow.Sheets do
  @moduledoc """
  Versioned sheet validation and normalization.
  """

  alias Cashflow.Money
  alias Cashflow.Sheets.{FastTrack, RatRace}

  @schema_version 1
  @phases ~w(rat_race fast_track)

  @rat_race_money_paths [
    ["income", "salary_cents"],
    ["income", "interest_cents"],
    ["income", "dividends_cents"],
    ["expenses", "taxes_cents"],
    ["expenses", "mortgage_cents"],
    ["expenses", "school_loan_cents"],
    ["expenses", "car_loan_cents"],
    ["expenses", "credit_card_cents"],
    ["expenses", "retail_cents"],
    ["expenses", "other_cents"],
    ["expenses", "miscellaneous_cents"],
    ["expenses", "per_child_cents"],
    ["assets", "savings_cents"],
    ["liabilities", "mortgage_cents"],
    ["liabilities", "school_loan_cents"],
    ["liabilities", "car_loan_cents"],
    ["liabilities", "credit_card_cents"],
    ["liabilities", "retail_cents"],
    ["liabilities", "bank_loan_cents"]
  ]

  @fast_track_money_paths [
    ["fast_track", "starting_passive_income_cents"],
    ["fast_track", "cashflow_day_income_cents"],
    ["fast_track", "portfolio_income_cents"],
    ["assets", "savings_cents"]
  ]

  def default_sheet(attrs \\ %{}), do: RatRace.new(attrs)

  def fast_track_sheet(attrs \\ %{}), do: FastTrack.new(attrs)

  def schema_version, do: @schema_version

  def normalize(sheet) when is_map(sheet) do
    sheet = stringify_keys(sheet)
    phase = Map.get(sheet, "phase", "rat_race")

    with :ok <- validate_phase(phase) do
      base = if phase == "fast_track", do: fast_track_sheet(), else: default_sheet()
      sheet = deep_merge(base, sheet)

      sheet =
        sheet
        |> Map.put("schema_version", @schema_version)
        |> normalize_children_count(phase)
        |> normalize_money_paths(money_paths(phase))

      {:ok, sheet}
    end
  end

  def normalize(_), do: {:error, :invalid_sheet}

  def normalize!(sheet) do
    case normalize(sheet) do
      {:ok, sheet} -> sheet
      {:error, reason} -> raise ArgumentError, "invalid sheet: #{inspect(reason)}"
    end
  end

  def transition_to_fast_track(sheet) do
    sheet = normalize!(sheet)

    fast_track_sheet(%{
      "meta" => Map.get(sheet, "meta", %{}),
      "assets" => %{"savings_cents" => get_in(sheet, ["assets", "savings_cents"]) || 0},
      "fast_track" => %{
        "starting_passive_income_cents" => Cashflow.Calculations.passive_income_cents(sheet),
        "cashflow_day_income_cents" =>
          Cashflow.Calculations.beginning_cashflow_day_income_cents(sheet)
      }
    })
  end

  def put_money(sheet, path, value) when is_list(path) do
    with {:ok, cents} <- Money.parse_cents(value),
         {:ok, sheet} <- normalize(sheet) do
      {:ok, put_in(sheet, path, cents)}
    end
  end

  def valid_path?(path) when is_binary(path) do
    path
    |> String.split(".")
    |> valid_path?()
  end

  def valid_path?(path) when is_list(path) do
    Enum.all?(path, &is_binary/1)
  end

  def diff(before_sheet, after_sheet) do
    before_sheet = normalize!(before_sheet)
    after_sheet = normalize!(after_sheet)

    changes = diff_values(before_sheet, after_sheet, [])

    %{
      "changes" => changes,
      "field_paths" => Enum.map(changes, & &1["path"]),
      "before_snapshot" => before_sheet,
      "after_snapshot" => after_sheet
    }
  end

  defp diff_values(%{} = before_value, %{} = after_value, path) do
    before_keys = Map.keys(before_value)
    after_keys = Map.keys(after_value)

    (before_keys ++ after_keys)
    |> Enum.uniq()
    |> Enum.flat_map(fn key ->
      diff_values(Map.get(before_value, key), Map.get(after_value, key), path ++ [key])
    end)
  end

  defp diff_values(before_value, after_value, path) do
    if before_value == after_value do
      []
    else
      [%{"path" => Enum.join(path, "."), "before" => before_value, "after" => after_value}]
    end
  end

  defp normalize_money_paths(sheet, paths),
    do: Enum.reduce(paths, sheet, &normalize_money(&2, &1))

  defp normalize_children_count(sheet, "rat_race"),
    do: normalize_integer(sheet, ["expenses", "children_count"])

  defp normalize_children_count(sheet, _phase), do: sheet

  defp normalize_money(sheet, path) do
    case Money.parse_cents(get_in(sheet, path)) do
      {:ok, cents} -> put_in(sheet, path, cents)
      {:error, _} -> put_in(sheet, path, 0)
    end
  end

  defp normalize_integer(sheet, path) do
    value =
      case get_in(sheet, path) do
        value when is_integer(value) -> value
        value when is_binary(value) -> String.to_integer(if(value == "", do: "0", else: value))
        _ -> 0
      end

    put_in(sheet, path, max(value, 0))
  rescue
    ArgumentError -> put_in(sheet, path, 0)
  end

  defp money_paths("fast_track"), do: @fast_track_money_paths
  defp money_paths(_), do: @rat_race_money_paths

  defp validate_phase(phase) when phase in @phases, do: :ok
  defp validate_phase(_), do: {:error, :invalid_phase}

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
