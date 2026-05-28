defmodule Cashflow.Sheets do
  @moduledoc """
  Versioned sheet validation and normalization.
  """

  alias Cashflow.Money
  alias Cashflow.Sheets.{FastTrack, RatRace}

  @schema_version 1
  @phases ~w(rat_race fast_track)
  @real_estate_count 4
  @business_count 2
  @stock_count 2
  @fast_track_investment_count 12

  @real_estate_row %{
    "name" => "",
    "down_payment_cents" => 0,
    "cost_cents" => 0,
    "mortgage_cents" => 0,
    "income_cents" => 0
  }
  @business_row %{
    "name" => "",
    "down_payment_cents" => 0,
    "cost_cents" => 0,
    "liability_cents" => 0,
    "income_cents" => 0
  }
  @stock_row %{"name" => "", "shares" => 0, "cost_per_share_cents" => 0}
  @fast_track_investment_row %{"name" => "", "cashflow_cents" => 0}

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
        |> normalize_phase_rows(phase)

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

  defp diff_values(before_values, after_values, path)
       when is_list(before_values) and is_list(after_values) do
    max_index = max(length(before_values), length(after_values)) - 1

    if max_index < 0 do
      []
    else
      Enum.flat_map(0..max_index, fn index ->
        diff_values(
          Enum.at(before_values, index),
          Enum.at(after_values, index),
          path ++ [to_string(index)]
        )
      end)
    end
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

  defp normalize_phase_rows(sheet, "fast_track") do
    normalize_fast_track_state(sheet)
  end

  defp normalize_phase_rows(sheet, _phase) do
    sheet
    |> normalize_rows(
      ["investments", "real_estate"],
      @real_estate_count,
      @real_estate_row,
      ~w(down_payment_cents cost_cents mortgage_cents income_cents),
      []
    )
    |> normalize_rows(
      ["investments", "businesses"],
      @business_count,
      @business_row,
      ~w(down_payment_cents cost_cents liability_cents income_cents),
      []
    )
    |> normalize_rows(
      ["investments", "stocks"],
      @stock_count,
      @stock_row,
      ~w(cost_per_share_cents),
      ~w(shares)
    )
    |> normalize_fast_track_state()
  end

  defp normalize_fast_track_state(sheet) do
    fast_track = Map.get(sheet, "fast_track", %{})

    fast_track =
      fast_track
      |> Map.put("dream", normalize_text(Map.get(fast_track, "dream")))
      |> Map.put("dream_completed", normalize_boolean(Map.get(fast_track, "dream_completed")))
      |> Map.put(
        "investments",
        normalized_rows(
          Map.get(fast_track, "investments"),
          @fast_track_investment_count,
          @fast_track_investment_row,
          ~w(cashflow_cents),
          []
        )
      )

    Map.put(sheet, "fast_track", fast_track)
  end

  defp normalize_rows(sheet, path, count, row_default, money_fields, integer_fields) do
    rows =
      sheet
      |> get_in(path)
      |> normalized_rows(count, row_default, money_fields, integer_fields)

    put_in(sheet, path, rows)
  end

  defp normalized_rows(rows, count, row_default, money_fields, integer_fields) do
    Enum.map(0..(count - 1), fn index ->
      rows
      |> row_at(index)
      |> normalize_row(row_default, money_fields, integer_fields)
    end)
  end

  defp normalize_row(row, row_default, money_fields, integer_fields) do
    row =
      row
      |> stringify_keys()
      |> case do
        %{} = row -> Map.merge(row_default, Map.take(row, Map.keys(row_default)))
        _ -> row_default
      end

    row
    |> Map.put("name", normalize_text(Map.get(row, "name")))
    |> normalize_row_money(money_fields)
    |> normalize_row_integers(integer_fields)
  end

  defp normalize_row_money(row, fields) do
    Enum.reduce(fields, row, fn field, row ->
      case Money.parse_cents(Map.get(row, field)) do
        {:ok, cents} -> Map.put(row, field, cents)
        {:error, _} -> Map.put(row, field, 0)
      end
    end)
  end

  defp normalize_row_integers(row, fields) do
    Enum.reduce(fields, row, fn field, row ->
      Map.put(row, field, parse_non_negative_integer(Map.get(row, field)))
    end)
  end

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

  defp parse_non_negative_integer(value) when is_integer(value), do: max(value, 0)

  defp parse_non_negative_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> max(integer, 0)
      _ -> 0
    end
  end

  defp parse_non_negative_integer(_), do: 0

  defp normalize_text(value) when is_binary(value), do: String.trim(value)
  defp normalize_text(nil), do: ""
  defp normalize_text(value), do: value |> to_string() |> String.trim()

  defp normalize_boolean(value) when is_list(value),
    do: value |> List.last() |> normalize_boolean()

  defp normalize_boolean(value), do: value in [true, "true", "1", 1, "on"]

  defp row_at(rows, index) when is_list(rows), do: Enum.at(rows, index, %{})

  defp row_at(%{} = rows, index),
    do: Map.get(rows, to_string(index)) || Map.get(rows, index) || %{}

  defp row_at(_rows, _index), do: %{}

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
