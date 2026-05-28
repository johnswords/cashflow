defmodule Cashflow.MoneyTest do
  use ExUnit.Case, async: true

  alias Cashflow.Money

  test "parses signed dollars to integer cents" do
    assert Money.parse_cents("$1,234.56") == {:ok, 123_456}
    assert Money.parse_cents("-42.10") == {:ok, -4_210}
    assert Money.parse_cents("") == {:ok, 0}
    assert Money.parse_cents("nope") == {:error, :invalid_money}
  end

  test "displays cents without losing sign or cents" do
    assert Money.display(123_456) == "$1234.56"
    assert Money.display(-4_200) == "-$42"
  end
end
