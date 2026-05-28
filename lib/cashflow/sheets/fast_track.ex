defmodule Cashflow.Sheets.FastTrack do
  @moduledoc """
  Version 1 Fast Track sheet shape.
  """

  defstruct schema_version: 1,
            phase: "fast_track",
            meta: %{"profession" => "", "auditor" => "", "notes" => ""},
            fast_track: %{
              "dream" => "",
              "starting_passive_income_cents" => 0,
              "cashflow_day_income_cents" => 0,
              "portfolio_income_cents" => 0,
              "dream_completed" => false,
              "investments" => List.duplicate(%{"name" => "", "cashflow_cents" => 0}, 12)
            },
            assets: %{"savings_cents" => 0},
            investments: %{"businesses" => []}

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
