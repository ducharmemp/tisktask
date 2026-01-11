defmodule Workers.TaskRunWorkerTest do
  use Tisktask.DataCase, async: true
  use Mimic

  alias Tisktask.SourceControl.Git
  alias Tisktask.Tasks

  @moduletag :integration

  setup do
    stub(Git, :clone_at, fn _, _, _, _ -> :ok end)
    stub(Git, :checkout, fn _, _, _ -> :ok end)
    :ok
  end

  describe "perform/1" do
    test "successfully performs a task run" do
      task_run = insert(:task_run)
      task_job = insert(:task_job, parent_run: task_run)

      assert :ok =
               Workers.TaskRunWorker.perform(%Oban.Job{
                 args: %{
                   "task_run_id" => task_run.id,
                   "task_job_id" => task_job.id
                 }
               })

      updated_task_job = Tasks.get_job!(task_job.id)
      assert updated_task_job.exit_status == 0
    end

    test "marks task run as failed on error" do
      task_run = insert(:task_run)
      task_job = insert(:task_job, parent_run: task_run, program_path: "non_existent_program")

      assert {:error, _} =
               Workers.TaskRunWorker.perform(%Oban.Job{
                 args: %{
                   "task_run_id" => task_run.id,
                   "task_job_id" => task_job.id
                 }
               })

      updated_task_job = Tasks.get_job!(task_job.id)
      assert updated_task_job.exit_status != 0
    end

    test "creates jobs per task file found in the folder for the event" do
    end
  end
end
