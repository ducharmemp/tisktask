defmodule Workers.TaskJobWorker do
  @moduledoc false
  use Oban.Worker, queue: :default, max_attempts: 2

  alias Tisktask.Commands
  alias Tisktask.Containers.Podman
  alias Tisktask.TaskLogs
  alias Tisktask.Tasks
  alias Tisktask.Triggers

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_run_id" => task_run_id, "task_job_id" => task_job_id}}) do
    task_run = Tasks.get_run!(task_run_id)
    task_job = Tasks.get_job!(task_job_id)

    :pg.join(:tisktask, :runners, self())

    try do
      if task_job.pod_id && Podman.pod_exists?(task_job.pod_id) do
        resume_job(task_run, task_job)
      else
        run_fresh_job(task_run, task_job)
      end
    after
      :pg.leave(:tisktask, :runners, self())
    end
  end

  defp run_fresh_job(task_run, task_job) do
    triggering_repository_name =
      task_run.trigger |> Triggers.repository_for!() |> Triggers.repository_name()

    triggering_sha = Triggers.head_sha(task_run.trigger)

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
    |> Map.put("TISKTASK_SOCKET_PATH", "/etc/tisktask/command.sock")
    |> then(fn mapped -> Tasks.Env.write_env_to(env_file, mapped) end)

    image = "localhost/#{triggering_repository_name}:#{triggering_sha}"

    pod_id = Podman.create_pod()
    task_job = Tasks.update_job!(task_job, %{pod_id: pod_id})

    container_id = Podman.create_container(pod_id, image, task_job.program_path, env_file, command_socket)
    task_job = Tasks.update_job!(task_job, %{container_id: container_id})

    Podman.start_pod(pod_id)
    Task.start(fn -> Podman.stream_logs(pod_id, TaskLogs.stream_to(task_job)) end)

    case Podman.wait_for_container_interruptible(container_id) do
      {:ok, exit_code} ->
        complete_job(task_run, task_job, pod_id, container_id, exit_code)

      {:interrupted, :shutdown} ->
        pause_and_reschedule(task_run, task_job, pod_id)

      {:error, :not_found} ->
        Tasks.update_job!(task_job, %{exit_status: -1})
        :ok
    end
  end

  defp resume_job(task_run, task_job) do
    case Podman.unpause_pod(task_job.pod_id) do
      :ok ->
        Task.start(fn -> Podman.stream_logs(task_job.pod_id, TaskLogs.stream_to(task_job)) end)

        case Podman.wait_for_container_interruptible(task_job.container_id) do
          {:ok, exit_code} ->
            complete_job(task_run, task_job, task_job.pod_id, task_job.container_id, exit_code)

          {:interrupted, :shutdown} ->
            pause_and_reschedule(task_run, task_job, task_job.pod_id)

          {:error, :not_found} ->
            Tasks.update_job!(task_job, %{exit_status: -1})
            :ok
        end

      {:error, _} ->
        Tasks.update_job!(task_job, %{exit_status: -1})
        :ok
    end
  end

  defp pause_and_reschedule(task_run, task_job, pod_id) do
    Podman.pause_pod(pod_id)

    %{task_run_id: task_run.id, task_job_id: task_job.id}
    |> __MODULE__.new(scheduled_at: DateTime.add(DateTime.utc_now(), 30, :second))
    |> Oban.insert!()

    {:snooze, 60}
  end

  defp complete_job(task_run, task_job, pod_id, container_id, exit_code) do
    Podman.cleanup(pod_id, container_id)
    status = if exit_code == 0, do: "success", else: "failure"

    Triggers.update_remote_status(
      task_run.trigger,
      task_run.id,
      task_job.program_path,
      status
    )

    Tasks.update_job!(task_job, %{exit_status: exit_code})
    :ok
  end
end
