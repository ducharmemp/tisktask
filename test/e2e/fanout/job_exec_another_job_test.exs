defmodule E2e.Fanout.JobExecAnotherJobTest do
  use Tisktask.DataCase, async: true

  describe "executing a job from a running job" do
    test "creates a new job" do
      job = insert(:task_job)

      result =
        Workers.TaskJobWorker.perform(%Oban.Job{
          args: %{"task_run_id" => job.task_run_id, "task_job_id" => job.id}
        })
    end

    test "allows the parent job to receive the exit status of the child job" do
    end
  end
end
