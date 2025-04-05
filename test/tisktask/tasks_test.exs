defmodule Tisktask.TasksTest do
  use Tisktask.DataCase

  alias Tisktask.Tasks

  describe "task_runs" do
    import Tisktask.TasksFixtures

    alias Tisktask.Tasks.Run

    @invalid_attrs %{status: nil}

    test "list_task_runs/0 returns all task_runs" do
      run = run_fixture()
      assert Tasks.list_task_runs() == [run]
    end

    test "get_run!/1 returns the run with given id" do
      run = run_fixture()
      assert Tasks.get_run!(run.id) == run
    end

    test "create_run/1 with valid data creates a run" do
      valid_attrs = %{status: "some status"}

      assert {:ok, %Run{} = run} = Tasks.create_run(valid_attrs)
      assert run.status == "some status"
    end

    test "create_run/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasks.create_run(@invalid_attrs)
    end

    test "update_run/2 with valid data updates the run" do
      run = run_fixture()
      update_attrs = %{status: "some updated status"}

      assert {:ok, %Run{} = run} = Tasks.update_run(run, update_attrs)
      assert run.status == "some updated status"
    end

    test "update_run/2 with invalid data returns error changeset" do
      run = run_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.update_run(run, @invalid_attrs)
      assert run == Tasks.get_run!(run.id)
    end

    test "delete_run/1 deletes the run" do
      run = run_fixture()
      assert {:ok, %Run{}} = Tasks.delete_run(run)
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_run!(run.id) end
    end

    test "change_run/1 returns a run changeset" do
      run = run_fixture()
      assert %Ecto.Changeset{} = Tasks.change_run(run)
    end
  end

  describe "task_run_logs" do
    import Tisktask.TasksFixtures

    alias Tisktask.Tasks.RunLog

    @invalid_attrs %{content: nil}

    test "list_task_run_logs/0 returns all task_run_logs" do
      run_log = run_log_fixture()
      assert Tasks.list_task_run_logs() == [run_log]
    end

    test "get_run_log!/1 returns the run_log with given id" do
      run_log = run_log_fixture()
      assert Tasks.get_run_log!(run_log.id) == run_log
    end

    test "create_run_log/1 with valid data creates a run_log" do
      valid_attrs = %{content: "some content"}

      assert {:ok, %RunLog{} = run_log} = Tasks.create_run_log(valid_attrs)
      assert run_log.content == "some content"
    end

    test "create_run_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasks.create_run_log(@invalid_attrs)
    end

    test "update_run_log/2 with valid data updates the run_log" do
      run_log = run_log_fixture()
      update_attrs = %{content: "some updated content"}

      assert {:ok, %RunLog{} = run_log} = Tasks.update_run_log(run_log, update_attrs)
      assert run_log.content == "some updated content"
    end

    test "update_run_log/2 with invalid data returns error changeset" do
      run_log = run_log_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.update_run_log(run_log, @invalid_attrs)
      assert run_log == Tasks.get_run_log!(run_log.id)
    end

    test "delete_run_log/1 deletes the run_log" do
      run_log = run_log_fixture()
      assert {:ok, %RunLog{}} = Tasks.delete_run_log(run_log)
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_run_log!(run_log.id) end
    end

    test "change_run_log/1 returns a run_log changeset" do
      run_log = run_log_fixture()
      assert %Ecto.Changeset{} = Tasks.change_run_log(run_log)
    end
  end
end
