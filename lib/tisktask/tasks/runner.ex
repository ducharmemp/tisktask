defmodule Tisktask.Tasks.Runner do
  @moduledoc """
  GenServer that manages the lifecycle of a task job execution.

  The runner transitions through the following stages using handle_continue:
  - `:initializing` - Setting up environment and command socket
  - `:creating_pod` - Creating Podman pod and container
  - `:running` - Pod started, streaming logs
  - `:waiting` - Waiting for container to complete
  - `:cleanup` - Removing pod and container
  - `:completed` - Job finished, reply sent to caller
  - `:interrupted` - SIGINT received, pod paused, retry signaled
  - `:resuming` - Resuming a previously paused pod

  ## SIGINT Handling

  When `broadcast_sigint/0` is called, all running runners will:
  1. Pause their executing pod via `Podman.pause_pod/1`
  2. Reply to the caller with `{:retry, :sigint}`
  3. Stop normally (without cleanup, preserving the paused pod)

  ## Resume Mode

  Runners can be started in resume mode via `start_link_resume/1` to resume
  a previously paused pod. This is used on startup to continue interrupted jobs.
  """
  use GenServer

  alias Tisktask.Commands
  alias Tisktask.Containers.Podman
  alias Tisktask.TaskLogs
  alias Tisktask.Tasks
  alias Tisktask.Triggers

  defstruct [
    :task_run,
    :task_job,
    :repository_name,
    :sha,
    :image,
    :env_file,
    :command_socket,
    :pod_id,
    :container_id,
    :exit_status,
    :error,
    :caller,
    :wait_ref,
    stage: :initialized
  ]

  # Client API

  def start_link(opts) do
    task_run_id = Keyword.fetch!(opts, :task_run_id)
    task_job_id = Keyword.fetch!(opts, :task_job_id)
    GenServer.start_link(__MODULE__, {:new, task_run_id, task_job_id}, opts)
  end

  def start_link_resume(opts) do
    task_job_id = Keyword.fetch!(opts, :task_job_id)
    GenServer.start_link(__MODULE__, {:resume, task_job_id}, opts)
  end

  def run(pid) do
    GenServer.call(pid, :run, :infinity)
  end

  def resume(pid) do
    GenServer.call(pid, :resume, :infinity)
  end

  # Server Callbacks

  @impl true
  def init({:new, task_run_id, task_job_id}) do
    task_run = Tasks.get_run!(task_run_id)
    task_job = Tasks.get_job!(task_job_id)

    repository = Triggers.repository_for!(task_run.trigger)
    repository_name = Triggers.repository_name(repository)
    sha = Triggers.head_sha(task_run.trigger)

    state = %__MODULE__{
      task_run: task_run,
      task_job: task_job,
      repository_name: repository_name,
      sha: sha,
      image: "localhost/#{repository_name}:#{sha}",
      stage: :initialized
    }

    {:ok, state}
  end

  def init({:resume, task_job_id}) do
    task_job = Tasks.get_job!(task_job_id)
    task_run = Tasks.get_run!(task_job.task_run_id)

    state = %__MODULE__{
      task_run: task_run,
      task_job: task_job,
      pod_id: task_job.pod_id,
      container_id: task_job.container_id,
      stage: :initialized_for_resume
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:run, from, %{stage: :initialized} = state) do
    {:noreply, %{state | caller: from}, {:continue, :initializing}}
  end

  def handle_call(:resume, from, %{stage: :initialized_for_resume} = state) do
    {:noreply, %{state | caller: from}, {:continue, :resuming}}
  end

  # State: initializing
  # Sets up environment file and command socket, updates remote status to pending
  @impl true
  def handle_continue(:initializing, state) do
    %{task_run: task_run, task_job: task_job} = state

    Triggers.update_remote_status(
      task_run.trigger,
      task_run.id,
      task_job.program_path,
      "pending"
    )

    command_socket = Commands.spawn_command_listeners(task_run, task_job)
    env_file = Tasks.Env.ensure_env_file!()

    task_run
    |> Tasks.env_for()
    |> Map.merge(Triggers.env_for(task_run.trigger))
    |> Map.put("TISKTASK_SOCKET_PATH", "/run/tisktask/command.sock")
    |> then(fn mapped -> Tasks.Env.write_env_to(env_file, mapped) end)

    new_state = %{
      state
      | command_socket: command_socket,
        env_file: env_file,
        stage: :initializing
    }

    {:noreply, new_state, {:continue, :creating_pod}}
  end

  # State: creating_pod
  # Creates Podman pod and container
  def handle_continue(:creating_pod, state) do
    %{image: image, task_job: task_job, env_file: env_file, command_socket: command_socket} = state

    pod_id = Podman.create_pod()
    task_job = Tasks.update_job!(task_job, %{pod_id: pod_id})

    container_id = Podman.create_container(pod_id, image, task_job.program_path, env_file, command_socket)
    task_job = Tasks.update_job!(task_job, %{container_id: container_id})

    new_state = %{
      state
      | pod_id: pod_id,
        container_id: container_id,
        task_job: task_job,
        stage: :creating_pod
    }

    {:noreply, new_state, {:continue, :running}}
  end

  # State: running
  # Starts the pod and begins log streaming
  def handle_continue(:running, state) do
    %{pod_id: pod_id, task_job: task_job} = state

    case Podman.start_pod(pod_id) do
      :ok ->
        Registry.register(Tisktask.Tasks.RunnerRegistry, :runners, pod_id)
        Task.start(fn -> Podman.stream_logs(pod_id, TaskLogs.stream_to(task_job)) end)
        {:noreply, %{state | stage: :running}, {:continue, :waiting}}

      {:error, reason} ->
        {:noreply, %{state | error: reason, stage: :running}, {:continue, :cleanup}}
    end
  end

  # State: waiting
  # Starts async wait for container exit
  def handle_continue(:waiting, state) do
    %{container_id: container_id} = state

    {:ok, ref} = Podman.wait_for_container_async(container_id)

    {:noreply, %{state | wait_ref: ref, stage: :waiting}}
  end

  # State: resuming
  # Resumes a previously paused pod
  def handle_continue(:resuming, state) do
    %{task_run: task_run, task_job: task_job, pod_id: pod_id} = state

    # Re-establish command socket listener for the container
    command_socket = Commands.spawn_command_listeners(task_run, task_job)

    case Podman.unpause_pod(pod_id) do
      :ok ->
        Registry.register(Tisktask.Tasks.RunnerRegistry, :runners, pod_id)
        Task.start(fn -> Podman.stream_logs(pod_id, TaskLogs.stream_to(task_job)) end)
        {:noreply, %{state | command_socket: command_socket, stage: :resuming}, {:continue, :waiting}}

      {:error, reason} ->
        {:noreply, %{state | error: reason, stage: :resuming}, {:continue, :cleanup}}
    end
  end

  # State: cleanup
  # Removes pod and container
  def handle_continue(:cleanup, state) do
    %{pod_id: pod_id, container_id: container_id} = state

    Podman.cleanup(pod_id, container_id)

    {:noreply, %{state | stage: :cleanup}, {:continue, :completed}}
  end

  # State: completed
  # Updates remote status, persists exit status, replies to caller
  def handle_continue(:completed, state) do
    %{task_run: task_run, task_job: task_job, exit_status: exit_status, error: error, caller: caller} = state

    {status, reply} =
      cond do
        error != nil -> {"failure", {:error, error}}
        exit_status == 0 -> {"success", {:ok, 0}}
        true -> {"failure", {:ok, exit_status}}
      end

    Triggers.update_remote_status(
      task_run.trigger,
      task_run.id,
      task_job.program_path,
      status
    )

    if exit_status, do: Tasks.update_job!(task_job, %{exit_status: exit_status})

    GenServer.reply(caller, reply)

    {:noreply, %{state | stage: :completed}}
  end

  # Handle container exit notification
  @impl true
  def handle_info({:container_exited, ref, _container_id, exit_status}, %{wait_ref: ref} = state) do
    {:noreply, %{state | exit_status: exit_status}, {:continue, :cleanup}}
  end

  # Handle SIGINT - pause the pod and signal retry needed
  def handle_info(:sigint, %{stage: stage, pod_id: pod_id, caller: caller} = state)
      when stage in [:running, :waiting] and pod_id != nil do
    Podman.pause_pod(pod_id)
    GenServer.reply(caller, {:retry, :sigint})
    {:stop, :normal, %{state | stage: :interrupted}}
  end

  def handle_info(:sigint, state) do
    # Ignore SIGINT if not in a running state or no pod to pause
    {:noreply, state}
  end

  @doc """
  Broadcasts SIGINT to all running task runners on this node.
  Each runner will pause its pod and reply with {:retry, :sigint}.
  """
  def broadcast_sigint do
    Registry.dispatch(Tisktask.Tasks.RunnerRegistry, :runners, fn entries ->
      for {pid, _pod_id} <- entries, do: send(pid, :sigint)
    end)
  end
end
