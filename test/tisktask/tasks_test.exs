defmodule Tisktask.TasksTest do
  use Tisktask.DataCase, async: true

  alias Tisktask.Tasks

  describe "task_runs" do
    alias Tisktask.Tasks.Run

    @invalid_attrs %{status: nil}

    test "list_task_runs/0 returns all task_runs" do
      run = insert(:task_run)
      assert Tasks.list_task_runs() == [run]
    end

    test "get_run!/1 returns the run with given id" do
      run = insert(:task_run)
      assert Tasks.get_run!(run.id) == run
    end

    test "create_run/1 with valid data creates a run" do
      trigger = insert(:trigger)

      assert {:ok, %Run{} = run} = Tasks.create_run(trigger)
      assert run.status == :staged
    end

    test "update_run/2 with valid data updates the run" do
      run = insert(:task_run)
      update_attrs = %{status: :running}

      assert {:ok, %Run{} = run} = Tasks.update_run(run, update_attrs)
      assert run.status == :running
    end

    test "update_run/2 with invalid data returns error changeset" do
      run = insert(:task_run)
      assert {:error, %Ecto.Changeset{}} = Tasks.update_run(run, @invalid_attrs)
      assert run == Tasks.get_run!(run.id)
    end

    test "change_run/1 returns a run changeset" do
      run = insert(:task_run)
      assert %Ecto.Changeset{} = Tasks.change_run(run)
    end
  end
end
