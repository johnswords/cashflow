defmodule Mix.Tasks.PostgresCompatScriptTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../../scripts/check-postgres-compat.sh", __DIR__)

  test "requires DATABASE_URL unless explicitly skipped" do
    {output, status} =
      System.cmd("bash", [@script],
        env: [{"DATABASE_URL", ""}, {"CASHFLOW_SKIP_POSTGRES_COMPAT", ""}],
        stderr_to_stdout: true
      )

    assert status == 1
    assert output =~ "DATABASE_URL is required"
  end

  test "can be skipped only with the explicit skip flag" do
    {output, status} =
      System.cmd("bash", [@script],
        env: [{"DATABASE_URL", ""}, {"CASHFLOW_SKIP_POSTGRES_COMPAT", "1"}],
        stderr_to_stdout: true
      )

    assert status == 0
    assert output =~ "CASHFLOW_SKIP_POSTGRES_COMPAT=1"
  end
end
