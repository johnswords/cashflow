defmodule Cashflow.Money do
  @moduledoc """
  Money helpers for the Cashflow domain.

  Persisted money is always signed integer cents. Display parsing may use
  Decimal, but database truth never uses floats or decimal strings.
  """

  @type cents :: integer()

  @doc """
  Converts a user/domain value to integer cents.
  """
  def parse_cents(value)

  def parse_cents(nil), do: {:ok, 0}
  def parse_cents(value) when is_integer(value), do: {:ok, value}

  def parse_cents(%Decimal{} = value) do
    value
    |> Decimal.mult(100)
    |> Decimal.round(0)
    |> Decimal.to_integer()
    |> then(&{:ok, &1})
  end

  def parse_cents(value) when is_binary(value) do
    value = String.trim(value)

    if value == "" do
      {:ok, 0}
    else
      value
      |> String.replace(~r/[$,\s]/, "")
      |> Decimal.parse()
      |> case do
        {decimal, ""} -> parse_cents(decimal)
        _ -> {:error, :invalid_money}
      end
    end
  end

  def parse_cents(_value), do: {:error, :invalid_money}

  def parse_cents!(value) do
    case parse_cents(value) do
      {:ok, cents} -> cents
      {:error, reason} -> raise ArgumentError, "invalid money value: #{inspect(reason)}"
    end
  end

  def add(values) when is_list(values), do: Enum.reduce(values, 0, &(&1 + &2))

  def display(cents) when is_integer(cents) do
    sign = if cents < 0, do: "-", else: ""
    cents = abs(cents)
    dollars = div(cents, 100)
    remainder = rem(cents, 100)

    if remainder == 0 do
      "#{sign}$#{dollars}"
    else
      "#{sign}$#{dollars}.#{String.pad_leading(Integer.to_string(remainder), 2, "0")}"
    end
  end
end
