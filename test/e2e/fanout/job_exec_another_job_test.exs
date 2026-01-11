defmodule E2e.Fanout.JobExecAnotherJobTest do
  use Tisktask.DataCase, async: true

  describe "executing a job from a running job" do
    @tag :skip
    test "creates a new job" do
      # This test requires full container infrastructure (Podman)
      # Skipping for now as it's an integration test
      job = insert(:task_job)

      _result =
        Workers.TaskJobWorker.perform(%Oban.Job{
          args: %{"task_run_id" => job.task_run_id, "task_job_id" => job.id}
        })
    end

    test "allows the parent job to receive the exit status of the child job" do
    end
  end
end
