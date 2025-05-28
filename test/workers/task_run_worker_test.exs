defmodule Workers.TaskRunWorkerTest do
  use Mimic
  use Tisktask.DataCase, async: true

  alias Tisktask.SourceControl.Git

  @moduletag :integration

  setup do
    expect(Git, :clone_at, fn _, _, _ -> :ok end)
    expect(Git, :checkout, fn _, _ -> :ok end)
  end

  describe "perform/1" do
    test "successfully performs a task run" do
      task_run = Tisktask.Tasks.create_run!(%{name: "Test Run", repository: "test_repo"})
      task_job = Tisktask.Tasks.create_job!(task_run, %{program_path: "test_program"})

      assert :ok =
               Workers.TaskRunWorker.perform(%Oban.Job{
                 args: %{
                   "task_run_id" => task_run.id,
                   "task_job_id" => task_job.id
                 }
               })

      updated_task_job = Tisktask.Tasks.get_job!(task_job.id)
      assert updated_task_job.exit_status == 0
    end

    test "marks task run as failed on error" do
      task_run = Tisktask.Tasks.create_run!(%{name: "Test Run", repository: "test_repo"})
      task_job = Tisktask.Tasks.create_job!(task_run, %{program_path: "non_existent_program"})

      assert {:error, _} =
               Workers.TaskRunWorker.perform(%Oban.Job{
                 args: %{
                   "task_run_id" => task_run.id,
                   "task_job_id" => task_job.id
                 }
               })

      updated_task_job = Tisktask.Tasks.get_job!(task_job.id)
      assert updated_task_job.exit_status != 0
    end

    test "creates jobs per task file found in the folder for the event" do
    end
  end
end
