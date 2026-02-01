defmodule Tisktask.Tasks.ResumePausedPodsTest do
  use Tisktask.DataCase, async: false
  use Mimic

  alias Tisktask.Containers.Podman
  alias Tisktask.Tasks.ResumePausedPods
  alias Tisktask.Tasks.Runner

  setup :set_mimic_global

  describe "run/0" do
    test "resumes paused pods that have matching task_jobs" do
      pod_id = "paused-pod-123"
      container_id = "container-456"
      test_pid = self()

      # Create a task_job with the pod_id
      task_run = insert(:task_run)
      task_job = insert(:task_job, parent_run: task_run, pod_id: pod_id, container_id: container_id)

      stub(Podman, :list_paused_pods, fn -> [pod_id] end)

      # Stub Runner to track that resume was called
      stub(Runner, :start_link_resume, fn opts ->
        send(test_pid, {:start_link_resume_called, opts[:task_job_id]})
        {:ok, spawn(fn -> Process.sleep(:infinity) end)}
      end)

      stub(Runner, :resume, fn _pid ->
        send(test_pid, :resume_called)
        {:ok, 0}
      end)

      ResumePausedPods.run()

      assert_receive {:start_link_resume_called, job_id}
      assert job_id == task_job.id

      # Wait for the async task to complete
      assert_receive :resume_called, 1000
    end

    test "skips pods without matching task_jobs" do
      pod_id = "orphan-pod-123"
      test_pid = self()

      stub(Podman, :list_paused_pods, fn -> [pod_id] end)

      # Runner should NOT be called for orphan pods
      stub(Runner, :start_link_resume, fn _opts ->
        send(test_pid, :should_not_be_called)
        {:ok, spawn(fn -> :ok end)}
      end)

      ResumePausedPods.run()

      refute_receive :should_not_be_called, 100
    end

    test "does nothing when no paused pods exist" do
      test_pid = self()

      stub(Podman, :list_paused_pods, fn -> [] end)

      stub(Runner, :start_link_resume, fn _opts ->
        send(test_pid, :should_not_be_called)
        {:ok, spawn(fn -> :ok end)}
      end)

      ResumePausedPods.run()

      refute_receive :should_not_be_called, 100
    end

    test "handles multiple paused pods" do
      pod_id_1 = "paused-pod-1"
      pod_id_2 = "paused-pod-2"
      test_pid = self()

      task_run = insert(:task_run)
      task_job_1 = insert(:task_job, parent_run: task_run, pod_id: pod_id_1, container_id: "c1")
      task_job_2 = insert(:task_job, parent_run: task_run, pod_id: pod_id_2, container_id: "c2")

      stub(Podman, :list_paused_pods, fn -> [pod_id_1, pod_id_2] end)

      stub(Runner, :start_link_resume, fn opts ->
        send(test_pid, {:start_link_resume_called, opts[:task_job_id]})
        {:ok, spawn(fn -> Process.sleep(:infinity) end)}
      end)

      stub(Runner, :resume, fn _pid ->
        send(test_pid, :resume_called)
        {:ok, 0}
      end)

      ResumePausedPods.run()

      assert_receive {:start_link_resume_called, id1}
      assert_receive {:start_link_resume_called, id2}
      assert Enum.sort([id1, id2]) == Enum.sort([task_job_1.id, task_job_2.id])
    end
  end

  describe "do_resume/2" do
    test "logs success on exit status 0" do
      pid = spawn(fn -> :ok end)

      stub(Runner, :resume, fn _pid -> {:ok, 0} end)

      # Should not raise
      assert :ok == ResumePausedPods.do_resume(pid, 123)
    end

    test "logs error on failure" do
      pid = spawn(fn -> :ok end)

      stub(Runner, :resume, fn _pid -> {:error, "something went wrong"} end)

      # Should not raise
      assert :ok == ResumePausedPods.do_resume(pid, 123)
    end

    test "logs warning on retry" do
      pid = spawn(fn -> :ok end)

      stub(Runner, :resume, fn _pid -> {:retry, :sigint} end)

      # Should not raise
      assert :ok == ResumePausedPods.do_resume(pid, 123)
    end
  end
end
