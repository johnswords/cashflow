defmodule Mix.Tasks.CashflowBackupRestoreTest do
  use Cashflow.DataCase, async: false

  alias Cashflow.Games
  alias Cashflow.Games.{AuditEvent, Game, LeaderboardRecord, Player}
  alias Cashflow.Repo

  describe "mix cashflow.backup.restore" do
    test "restores backup JSON transactionally and preserves completed-game snapshots" do
      backup = completed_backup()
      path = write_backup!(backup)

      assert {_output, :ok} =
               capture_task(fn ->
                 Mix.Task.rerun("cashflow.backup.restore", [path, "--replace"])
               end)

      assert Repo.aggregate(Game, :count) == 1
      assert Repo.aggregate(Player, :count) == 2
      assert Repo.aggregate(AuditEvent, :count) == 2
      assert Repo.aggregate(LeaderboardRecord, :count) == 2

      completed = Repo.one!(Game)
      restored_player = Repo.get!(Player, completed.winner_player_id)

      assert completed.status == "completed"

      assert {:error, :completed_game} =
               Games.save_player_sheet(
                 completed.id,
                 restored_player.id,
                 put_in(restored_player.sheet_state, ["income", "salary_cents"], 400_000),
                 baseline_lock_version: restored_player.lock_version
               )

      assert [%{winner_comment: "Won big"}] =
               Games.list_leaderboard_records()
               |> Enum.filter(&(&1.player_id == restored_player.id))
    end

    test "refuses to import into a non-empty database without --replace" do
      backup = completed_backup()
      path = write_backup!(backup)

      assert_raise Mix.Error, ~r/Database already has Cashflow data/, fn ->
        capture_task(fn ->
          Mix.Task.rerun("cashflow.backup.restore", [path])
        end)
      end

      assert Repo.aggregate(Game, :count) == 1
    end

    test "validates schema version before replacing existing data" do
      backup = completed_backup() |> Map.put(:schema_version, 999)
      path = write_backup!(backup)

      assert_raise Mix.Error, ~r/Unsupported backup schema_version/, fn ->
        capture_task(fn ->
          Mix.Task.rerun("cashflow.backup.restore", [path, "--replace"])
        end)
      end

      assert Repo.aggregate(Game, :count) == 1
      assert Repo.aggregate(Player, :count) == 2
    end
  end

  defp completed_backup do
    {:ok, game} =
      Games.create_game(%{
        title: "Fixture Game",
        players: [
          %{"name" => "Henry", "color" => "blue"},
          %{"name" => "Ashley", "color" => "green"}
        ]
      })

    player = hd(game.players)
    sheet = put_in(player.sheet_state, ["income", "salary_cents"], 300_000)

    {:ok, %{player: player}} =
      Games.save_player_sheet(game.id, player.id, sheet,
        baseline_lock_version: player.lock_version
      )

    {:ok, %{game: completed}} =
      Games.complete_game(game.id, %{
        "winner_player_id" => player.id,
        "winner_comment" => "Won big"
      })

    assert completed.status == "completed"

    Games.export_data()
  end

  defp write_backup!(backup) do
    path =
      Path.join(
        System.tmp_dir!(),
        "cashflow-backup-#{System.unique_integer([:positive])}.json"
      )

    File.write!(path, Jason.encode!(backup))
    on_exit(fn -> File.rm(path) end)

    path
  end

  defp capture_task(fun) do
    ExUnit.CaptureIO.capture_io(fun)
    |> then(&{&1, :ok})
  end
end
