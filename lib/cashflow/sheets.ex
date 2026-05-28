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

  @real_estate_fields ~w(name down_payment_cents cost_cents mortgage_cents income_cents)
  @business_fields ~w(name down_payment_cents cost_cents liability_cents income_cents)
  @stock_fields ~w(name shares cost_per_share_cents)
  @fast_track_investment_fields ~w(name cashflow_cents)

  @static_path_labels %{
    "schema_version" => "Schema Version",
    "phase" => "Phase",
    "meta" => "Profile",
    "meta.profession" => "Profession",
    "meta.auditor" => "Auditor",
    "meta.notes" => "Profile Notes",
    "income" => "Income",
    "income.salary_cents" => "Salary",
    "income.interest_cents" => "Interest",
    "income.dividends_cents" => "Dividends",
    "expenses" => "Expenses",
    "expenses.taxes_cents" => "Taxes",
    "expenses.mortgage_cents" => "Mortgage Payment",
    "expenses.school_loan_cents" => "School Loan Payment",
    "expenses.car_loan_cents" => "Car Loan Payment",
    "expenses.credit_card_cents" => "Credit Card Payment",
    "expenses.retail_cents" => "Retail Payment",
    "expenses.other_cents" => "Other Expenses",
    "expenses.miscellaneous_cents" => "Miscellaneous",
    "expenses.children_count" => "Children",
    "expenses.per_child_cents" => "Per Child Expense",
    "assets" => "Assets",
    "assets.savings_cents" => "Savings",
    "liabilities" => "Liabilities",
    "liabilities.mortgage_cents" => "Mortgage Liability",
    "liabilities.school_loan_cents" => "School Loan Liability",
    "liabilities.car_loan_cents" => "Car Loan Liability",
    "liabilities.credit_card_cents" => "Credit Card Liability",
    "liabilities.retail_cents" => "Retail Liability",
    "liabilities.bank_loan_cents" => "Bank Loan Liability",
    "investments" => "Investments",
    "investments.real_estate" => "Real Estate",
    "investments.businesses" => "Businesses",
    "investments.stocks" => "Stocks / Mutual Funds / CDs",
    "fast_track" => "Fast Track",
    "fast_track.dream" => "Dream",
    "fast_track.starting_passive_income_cents" => "Starting Passive Income",
    "fast_track.cashflow_day_income_cents" => "Cashflow Day Income",
    "fast_track.portfolio_income_cents" => "Portfolio Income",
    "fast_track.dream_completed" => "Dream Completed",
    "fast_track.investments" => "Fast Track Investments"
  }

  @valid_static_paths MapSet.new(Map.keys(@static_path_labels))

  def default_sheet(attrs \\ %{}), do: RatRace.new(attrs)

  def fast_track_sheet(attrs \\ %{}), do: FastTrack.new(attrs)

  def schema_version, do: @schema_version

  def normalize(sheet) when is_map(sheet) do
    sheet = stringify_keys(sheet)
    phase = Map.get(sheet, "phase", "rat_race")

    with :ok <- validate_phase(phase) do
      base = if phase == "fast_track", do: fast_track_sheet(), else: default_sheet()
      sheet = deep_merge(base, prune_to_shape(sheet, base))

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
    |> split_path()
    |> valid_path?()
  end

  def valid_path?(path) when is_list(path) do
    Enum.all?(path, &valid_path_segment?/1) and valid_path_segments?(path)
  end

  def valid_path?(_), do: false

  def field_label(path) when is_binary(path) do
    path
    |> split_path()
    |> field_label()
  end

  def field_label(path) when is_list(path) do
    path = Enum.map(path, &to_string/1)

    Map.get(@static_path_labels, Enum.join(path, ".")) || row_field_label(path) ||
      humanize_path(path)
  end

  def field_label(_), do: "Unknown Field"

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

  defp valid_path_segments?(path) do
    MapSet.member?(@valid_static_paths, Enum.join(path, ".")) or valid_row_path?(path)
  end

  defp valid_row_path?(["investments", "real_estate", index]),
    do: valid_index?(index, @real_estate_count)

  defp valid_row_path?(["investments", "real_estate", index, field]),
    do: valid_index?(index, @real_estate_count) and field in @real_estate_fields

  defp valid_row_path?(["investments", "businesses", index]),
    do: valid_index?(index, @business_count)

  defp valid_row_path?(["investments", "businesses", index, field]),
    do: valid_index?(index, @business_count) and field in @business_fields

  defp valid_row_path?(["investments", "stocks", index]),
    do: valid_index?(index, @stock_count)

  defp valid_row_path?(["investments", "stocks", index, field]),
    do: valid_index?(index, @stock_count) and field in @stock_fields

  defp valid_row_path?(["fast_track", "investments", index]),
    do: valid_index?(index, @fast_track_investment_count)

  defp valid_row_path?(["fast_track", "investments", index, field]),
    do:
      valid_index?(index, @fast_track_investment_count) and field in @fast_track_investment_fields

  defp valid_row_path?(_), do: false

  defp row_field_label(["investments", "real_estate", index]),
    do: indexed_label("Property", index)

  defp row_field_label(["investments", "real_estate", index, field]),
    do: indexed_field_label("Property", index, field)

  defp row_field_label(["investments", "businesses", index]),
    do: indexed_label("Business", index)

  defp row_field_label(["investments", "businesses", index, field]),
    do: indexed_field_label("Business", index, field)

  defp row_field_label(["investments", "stocks", index]),
    do: indexed_label("Stock", index)

  defp row_field_label(["investments", "stocks", index, field]),
    do: indexed_field_label("Stock", index, field)

  defp row_field_label(["fast_track", "investments", index]),
    do: indexed_label("Fast Track Investment", index)

  defp row_field_label(["fast_track", "investments", index, field]),
    do: indexed_field_label("Fast Track Investment", index, field)

  defp row_field_label(_), do: nil

  defp indexed_field_label(prefix, index, "name"), do: indexed_label(prefix, index)

  defp indexed_field_label(prefix, index, "income_cents")
       when prefix in ["Property", "Business"],
       do: "#{indexed_label(prefix, index)} Cashflow"

  defp indexed_field_label(prefix, index, field),
    do: "#{indexed_label(prefix, index)} #{humanize_segment(field)}"

  defp indexed_label(prefix, index) do
    case Integer.parse(index) do
      {number, ""} -> "#{prefix} #{number + 1}"
      _ -> nil
    end
  end

  defp humanize_path([]), do: "Unknown Field"

  defp humanize_path(path) do
    path
    |> List.last()
    |> humanize_segment()
  end

  defp humanize_segment(segment) do
    segment
    |> String.replace_suffix("_cents", "")
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
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

  defp valid_path_segment?(segment), do: is_binary(segment) and segment != ""

  defp valid_index?(index, count) do
    case Integer.parse(index) do
      {integer, ""} -> integer >= 0 and integer < count
      _ -> false
    end
  end

  defp split_path(path) do
    String.split(path, ".", trim: true)
  end

  defp prune_to_shape(%{} = input, %{} = shape) do
    input
    |> Map.take(Map.keys(shape))
    |> Map.new(fn {key, value} ->
      {key, prune_to_shape(value, Map.get(shape, key))}
    end)
  end

  defp prune_to_shape(value, shape) when is_list(shape), do: value
  defp prune_to_shape(value, _shape), do: value

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
