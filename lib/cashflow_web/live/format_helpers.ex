defmodule CashflowWeb.FormatHelpers do
  @moduledoc false

  alias Cashflow.Money

  def money(cents) when is_integer(cents), do: Money.display(cents)
  def money(_), do: "$0"

  def status_label("completed"), do: "Completed"
  def status_label("active"), do: "Active"
  def status_label(status), do: Phoenix.Naming.humanize(status || "")

  def phase_label("fast_track"), do: "Fast Track"
  def phase_label("rat_race"), do: "Rat Race"
  def phase_label(phase), do: Phoenix.Naming.humanize(phase || "")

  def player_color_class("blue"), do: "bg-blue-600"
  def player_color_class("green"), do: "bg-green-600"
  def player_color_class("purple"), do: "bg-purple-600"
  def player_color_class("orange"), do: "bg-orange-600"
  def player_color_class("red"), do: "bg-red-600"
  def player_color_class("yellow"), do: "bg-yellow-600"
  def player_color_class(_), do: "bg-slate-600"
end
