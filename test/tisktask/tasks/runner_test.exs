defmodule Tisktask.Tasks.RunnerTest do
  use Tisktask.DataCase, async: false
  use Mimic

  alias Tisktask.Commands
  alias Tisktask.Containers.Podman
  alias Tisktask.TaskLogs
  alias Tisktask.Tasks
  alias Tisktask.Tasks.Env
  alias Tisktask.Tasks.Runner
  alias Tisktask.Triggers

  setup :set_mimic_global

  setup do
    task_run = insert(:task_run)
    task_job = insert(:task_job, parent_run: task_run, exit_status: nil)

    {:ok, env_file} = Briefly.create()
    {:ok, socket_path} = Briefly.create()

    # Stub common external dependencies
    stub(Commands, :spawn_command_listeners, fn _, _ -> socket_path end)
    stub(Env, :ensure_env_file!, fn -> env_file end)
    stub(Env, :write_env_to, fn _, _ -> :ok end)
    stub(TaskLogs, :stream_to, fn _ -> fn _ -> :ok end end)
    stub(Triggers, :update_remote_status, fn _, _, _, _ -> :ok end)

    %{
      task_run: task_run,
      task_job: task_job,
      env_file: env_file,
      socket_path: socket_path
    }
  end

  describe "run/1" do
    test "executes job through all stages and returns exit status", ctx do
      %{task_run: task_run, task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"

      stub_podman(pod_id, container_id, _exit_status = 0)

      {:ok, pid} = Runner.start_link(task_run_id: task_run.id, task_job_id: task_job.id)

      assert {:ok, 0} = Runner.run(pid)

      # Verify job was updated with pod_id, container_id, and exit_status
      updated_job = Tasks.get_job!(task_job.id)
      assert updated_job.pod_id == pod_id
      assert updated_job.container_id == container_id
      assert updated_job.exit_status == 0
    end

    test "returns non-zero exit status on container failure", ctx do
      %{task_run: task_run, task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"

      stub_podman(pod_id, container_id, _exit_status = 1)

      {:ok, pid} = Runner.start_link(task_run_id: task_run.id, task_job_id: task_job.id)

      assert {:ok, 1} = Runner.run(pid)

      updated_job = Tasks.get_job!(task_job.id)
      assert updated_job.exit_status == 1
    end

    test "updates remote status to pending at start and success on completion", ctx do
      %{task_run: task_run, task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"
      test_pid = self()

      stub_podman(pod_id, container_id, _exit_status = 0)

      # Track status updates
      stub(Triggers, :update_remote_status, fn _trigger, _run_id, _program_path, status ->
        send(test_pid, {:status_update, status})
        :ok
      end)

      {:ok, pid} = Runner.start_link(task_run_id: task_run.id, task_job_id: task_job.id)
      assert {:ok, 0} = Runner.run(pid)

      # Verify we got pending first, then success
      assert_received {:status_update, "pending"}
      assert_received {:status_update, "success"}
    end

    test "updates remote status to failure when container exits non-zero", ctx do
      %{task_run: task_run, task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"
      test_pid = self()

      stub_podman(pod_id, container_id, _exit_status = 1)

      stub(Triggers, :update_remote_status, fn _trigger, _run_id, _program_path, status ->
        send(test_pid, {:status_update, status})
        :ok
      end)

      {:ok, pid} = Runner.start_link(task_run_id: task_run.id, task_job_id: task_job.id)
      assert {:ok, 1} = Runner.run(pid)

      assert_received {:status_update, "pending"}
      assert_received {:status_update, "failure"}
    end

    test "sets up environment with socket path", ctx do
      %{task_run: task_run, task_job: task_job, env_file: env_file} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"
      test_pid = self()

      stub_podman(pod_id, container_id, _exit_status = 0)

      stub(Env, :write_env_to, fn ^env_file, env_map ->
        send(test_pid, {:env_written, env_map})
        :ok
      end)

      {:ok, pid} = Runner.start_link(task_run_id: task_run.id, task_job_id: task_job.id)
      assert {:ok, 0} = Runner.run(pid)

      assert_received {:env_written, env_map}
      assert env_map["TISKTASK_SOCKET_PATH"] == "/run/tisktask/command.sock"
    end

    test "cleans up pod and container after completion", ctx do
      %{task_run: task_run, task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"
      test_pid = self()

      stub(Podman, :create_pod, fn -> pod_id end)
      stub(Podman, :create_container, fn _, _, _, _, _ -> container_id end)
      stub(Podman, :start_pod, fn _ -> :ok end)
      stub(Podman, :stream_logs, fn _, _ -> :ok end)

      stub(Podman, :wait_for_container_async, fn _cid ->
        ref = make_ref()
        send(self(), {:container_exited, ref, container_id, 0})
        {:ok, ref}
      end)

      stub(Podman, :cleanup, fn p_id, c_id ->
        send(test_pid, {:cleanup_called, p_id, c_id})
        :ok
      end)

      {:ok, pid} = Runner.start_link(task_run_id: task_run.id, task_job_id: task_job.id)
      assert {:ok, 0} = Runner.run(pid)

      assert_received {:cleanup_called, ^pod_id, ^container_id}
    end

    test "returns error when start_pod fails", ctx do
      %{task_run: task_run, task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"
      error_message = "script is not executable"
      test_pid = self()

      stub(Podman, :create_pod, fn -> pod_id end)
      stub(Podman, :create_container, fn _, _, _, _, _ -> container_id end)
      stub(Podman, :start_pod, fn _ -> {:error, error_message} end)
      stub(Podman, :stream_logs, fn _, _ -> :ok end)
      stub(Podman, :cleanup, fn _, _ -> :ok end)

      stub(Triggers, :update_remote_status, fn _trigger, _run_id, _program_path, status ->
        send(test_pid, {:status_update, status})
        :ok
      end)

      {:ok, pid} = Runner.start_link(task_run_id: task_run.id, task_job_id: task_job.id)
      assert {:error, ^error_message} = Runner.run(pid)

      assert_received {:status_update, "pending"}
      assert_received {:status_update, "failure"}
    end
  end

  describe "SIGINT handling" do
    test "broadcast_sigint pauses pod and returns {:retry, :sigint}", ctx do
      %{task_run: task_run, task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"
      test_pid = self()

      stub(Podman, :create_pod, fn -> pod_id end)
      stub(Podman, :create_container, fn _, _, _, _, _ -> container_id end)
      stub(Podman, :start_pod, fn _ -> :ok end)
      stub(Podman, :stream_logs, fn _, _ -> :ok end)

      # This will block waiting for container exit
      stub(Podman, :wait_for_container_async, fn _cid ->
        ref = make_ref()
        # Don't send exit message - we'll send SIGINT instead
        {:ok, ref}
      end)

      stub(Podman, :pause_pod, fn p_id ->
        send(test_pid, {:pause_called, p_id})
        :ok
      end)

      {:ok, pid} = Runner.start_link(task_run_id: task_run.id, task_job_id: task_job.id)

      # Start run in a task so we can send SIGINT
      run_task =
        Task.async(fn ->
          Runner.run(pid)
        end)

      # Wait for the runner to reach waiting stage
      Process.sleep(50)

      # Send SIGINT
      send(pid, :sigint)

      # Should get retry response
      assert {:retry, :sigint} = Task.await(run_task)

      # Verify pause was called
      assert_received {:pause_called, ^pod_id}
    end

    test "broadcast_sigint sends sigint to all registered runners", ctx do
      %{task_run: task_run, task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"
      test_pid = self()

      stub(Podman, :create_pod, fn -> pod_id end)
      stub(Podman, :create_container, fn _, _, _, _, _ -> container_id end)
      stub(Podman, :start_pod, fn _ -> :ok end)
      stub(Podman, :stream_logs, fn _, _ -> :ok end)

      stub(Podman, :wait_for_container_async, fn _cid ->
        ref = make_ref()
        {:ok, ref}
      end)

      stub(Podman, :pause_pod, fn p_id ->
        send(test_pid, {:pause_called, p_id})
        :ok
      end)

      {:ok, pid} = Runner.start_link(task_run_id: task_run.id, task_job_id: task_job.id)

      run_task =
        Task.async(fn ->
          Runner.run(pid)
        end)

      # Wait for runner to register
      Process.sleep(50)

      # Broadcast SIGINT to all runners
      Runner.broadcast_sigint()

      assert {:retry, :sigint} = Task.await(run_task)
      assert_received {:pause_called, ^pod_id}
    end

    test "ignores sigint when not in running/waiting stage", ctx do
      %{task_run: task_run, task_job: task_job} = ctx

      {:ok, pid} = Runner.start_link(task_run_id: task_run.id, task_job_id: task_job.id)

      # Send SIGINT before run is called (stage is :initialized)
      send(pid, :sigint)

      # Process should still be alive
      assert Process.alive?(pid)
    end
  end

  describe "resume/1" do
    test "resumes a paused pod and returns exit status", ctx do
      %{task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"
      test_pid = self()

      # Update job with pod_id and container_id (simulating a previously interrupted job)
      task_job = Tasks.update_job!(task_job, %{pod_id: pod_id, container_id: container_id})

      stub(Commands, :spawn_command_listeners, fn _, _ -> "/tmp/socket" end)
      stub(TaskLogs, :stream_to, fn _ -> fn _ -> :ok end end)
      stub(Triggers, :update_remote_status, fn _, _, _, _ -> :ok end)

      stub(Podman, :unpause_pod, fn p_id ->
        send(test_pid, {:unpause_called, p_id})
        :ok
      end)

      stub(Podman, :stream_logs, fn _, _ -> :ok end)
      stub(Podman, :cleanup, fn _, _ -> :ok end)

      stub(Podman, :wait_for_container_async, fn _cid ->
        ref = make_ref()
        send(self(), {:container_exited, ref, container_id, 0})
        {:ok, ref}
      end)

      {:ok, pid} = Runner.start_link_resume(task_job_id: task_job.id)

      assert {:ok, 0} = Runner.resume(pid)
      assert_received {:unpause_called, ^pod_id}
    end

    test "returns error when unpause fails", ctx do
      %{task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"

      task_job = Tasks.update_job!(task_job, %{pod_id: pod_id, container_id: container_id})

      stub(Commands, :spawn_command_listeners, fn _, _ -> "/tmp/socket" end)
      stub(Triggers, :update_remote_status, fn _, _, _, _ -> :ok end)

      stub(Podman, :unpause_pod, fn _ -> {:error, "pod not found"} end)
      stub(Podman, :cleanup, fn _, _ -> :ok end)

      {:ok, pid} = Runner.start_link_resume(task_job_id: task_job.id)

      assert {:error, "pod not found"} = Runner.resume(pid)
    end

    test "re-establishes command socket on resume", ctx do
      %{task_job: task_job} = ctx

      pod_id = "test-pod-123"
      container_id = "test-container-456"
      test_pid = self()

      task_job = Tasks.update_job!(task_job, %{pod_id: pod_id, container_id: container_id})

      stub(Commands, :spawn_command_listeners, fn run, job ->
        send(test_pid, {:socket_spawned, run.id, job.id})
        "/tmp/socket"
      end)

      stub(TaskLogs, :stream_to, fn _ -> fn _ -> :ok end end)
      stub(Triggers, :update_remote_status, fn _, _, _, _ -> :ok end)
      stub(Podman, :unpause_pod, fn _ -> :ok end)
      stub(Podman, :stream_logs, fn _, _ -> :ok end)
      stub(Podman, :cleanup, fn _, _ -> :ok end)

      stub(Podman, :wait_for_container_async, fn _cid ->
        ref = make_ref()
        send(self(), {:container_exited, ref, container_id, 0})
        {:ok, ref}
      end)

      {:ok, pid} = Runner.start_link_resume(task_job_id: task_job.id)

      assert {:ok, 0} = Runner.resume(pid)
      assert_received {:socket_spawned, _, _}
    end
  end

  defp stub_podman(pod_id, container_id, exit_status) do
    stub(Podman, :create_pod, fn -> pod_id end)
    stub(Podman, :create_container, fn _, _, _, _, _ -> container_id end)
    stub(Podman, :start_pod, fn _ -> :ok end)
    stub(Podman, :stream_logs, fn _, _ -> :ok end)
    stub(Podman, :cleanup, fn _, _ -> :ok end)

    # Note: wait_for_container_async has a default arg, so we stub arity 1
    stub(Podman, :wait_for_container_async, fn _cid ->
      ref = make_ref()
      send(self(), {:container_exited, ref, container_id, exit_status})
      {:ok, ref}
    end)
  end
end
