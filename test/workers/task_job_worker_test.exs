defmodule Workers.TaskJobWorkerTest do
  use Tisktask.DataCase, async: false
  use Mimic

  alias Tisktask.Containers.Podman
  alias Tisktask.Tasks
  alias Tisktask.Triggers

  setup :set_mimic_global

  setup do
    stub(Triggers, :repository_for!, fn _ -> %{full_name: "test/repo"} end)
    stub(Triggers, :repository_name, fn _ -> "test-repo" end)
    stub(Triggers, :head_sha, fn _ -> "abc123" end)
    stub(Triggers, :update_remote_status, fn _, _, _, _ -> :ok end)
    stub(Triggers, :env_for, fn _ -> %{} end)
    :ok
  end

  describe "perform/1 fresh job" do
    test "runs fresh job and records exit status" do
      stub(Podman, :create_pod, fn -> "test-pod-id" end)
      stub(Podman, :create_container, fn _, _, _, _, _ -> "test-container-id" end)
      stub(Podman, :start_pod, fn _ -> :ok end)
      stub(Podman, :stream_logs, fn _, _ -> :ok end)
      stub(Podman, :cleanup, fn _, _ -> :ok end)
      stub(Podman, :pod_exists?, fn _ -> false end)
      stub(Podman, :wait_for_container_interruptible, fn _ -> {:ok, 0} end)

      task_run = insert(:task_run)
      task_job = insert(:task_job, parent_run: task_run, pod_id: nil, container_id: nil)

      assert :ok =
               Workers.TaskJobWorker.perform(%Oban.Job{
                 args: %{
                   "task_run_id" => task_run.id,
                   "task_job_id" => task_job.id
                 }
               })

      updated_job = Tasks.get_job!(task_job.id)
      assert updated_job.exit_status == 0
      assert updated_job.pod_id == "test-pod-id"
      assert updated_job.container_id == "test-container-id"
    end

    test "records non-zero exit status on failure" do
      stub(Podman, :create_pod, fn -> "test-pod-id" end)
      stub(Podman, :create_container, fn _, _, _, _, _ -> "test-container-id" end)
      stub(Podman, :start_pod, fn _ -> :ok end)
      stub(Podman, :stream_logs, fn _, _ -> :ok end)
      stub(Podman, :cleanup, fn _, _ -> :ok end)
      stub(Podman, :pod_exists?, fn _ -> false end)
      stub(Podman, :wait_for_container_interruptible, fn _ -> {:ok, 42} end)

      task_run = insert(:task_run)
      task_job = insert(:task_job, parent_run: task_run, pod_id: nil, container_id: nil)

      assert :ok =
               Workers.TaskJobWorker.perform(%Oban.Job{
                 args: %{
                   "task_run_id" => task_run.id,
                   "task_job_id" => task_job.id
                 }
               })

      updated_job = Tasks.get_job!(task_job.id)
      assert updated_job.exit_status == 42
    end
  end

  describe "perform/1 resume job" do
    test "resumes job when pod_id exists and pod exists" do
      stub(Podman, :pod_exists?, fn "existing-pod-id" -> true end)
      stub(Podman, :unpause_pod, fn _ -> :ok end)
      stub(Podman, :stream_logs, fn _, _ -> :ok end)
      stub(Podman, :cleanup, fn _, _ -> :ok end)
      stub(Podman, :wait_for_container_interruptible, fn _ -> {:ok, 0} end)

      task_run = insert(:task_run)

      task_job =
        insert(:task_job,
          parent_run: task_run,
          pod_id: "existing-pod-id",
          container_id: "existing-container-id",
          exit_status: nil
        )

      assert :ok =
               Workers.TaskJobWorker.perform(%Oban.Job{
                 args: %{
                   "task_run_id" => task_run.id,
                   "task_job_id" => task_job.id
                 }
               })

      updated_job = Tasks.get_job!(task_job.id)
      assert updated_job.exit_status == 0
    end

    test "marks job failed when unpause fails" do
      stub(Podman, :pod_exists?, fn _ -> true end)
      stub(Podman, :unpause_pod, fn _ -> {:error, "pod not found"} end)

      task_run = insert(:task_run)

      task_job =
        insert(:task_job,
          parent_run: task_run,
          pod_id: "broken-pod-id",
          container_id: "broken-container-id",
          exit_status: nil
        )

      assert :ok =
               Workers.TaskJobWorker.perform(%Oban.Job{
                 args: %{
                   "task_run_id" => task_run.id,
                   "task_job_id" => task_job.id
                 }
               })

      updated_job = Tasks.get_job!(task_job.id)
      assert updated_job.exit_status == -1
    end
  end

  describe "perform/1 graceful shutdown" do
    test "pauses pod and reschedules on shutdown signal" do
      import Ecto.Query

      stub(Podman, :create_pod, fn -> "test-pod-id" end)
      stub(Podman, :create_container, fn _, _, _, _, _ -> "test-container-id" end)
      stub(Podman, :start_pod, fn _ -> :ok end)
      stub(Podman, :stream_logs, fn _, _ -> :ok end)
      stub(Podman, :pod_exists?, fn _ -> false end)
      stub(Podman, :pause_pod, fn _ -> :ok end)
      stub(Podman, :wait_for_container_interruptible, fn _ -> {:interrupted, :shutdown} end)

      task_run = insert(:task_run)
      task_job = insert(:task_job, parent_run: task_run, pod_id: nil, container_id: nil)

      assert {:snooze, 60} =
               Workers.TaskJobWorker.perform(%Oban.Job{
                 args: %{
                   "task_run_id" => task_run.id,
                   "task_job_id" => task_job.id
                 }
               })

      # Verify a new job was scheduled
      scheduled_jobs =
        Tisktask.Repo.all(
          from j in Oban.Job,
            where: j.worker == "Workers.TaskJobWorker",
            where: j.state == "scheduled"
        )

      assert length(scheduled_jobs) == 1
      scheduled_job = hd(scheduled_jobs)
      assert scheduled_job.args["task_job_id"] == task_job.id
    end
  end
end
