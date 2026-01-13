defmodule Workers.TaskJobWorker do
  @moduledoc false
  use Oban.Worker, queue: :default, max_attempts: 1

  alias Tisktask.Commands
  alias Tisktask.Containers.Podman
  alias Tisktask.TaskLogs
  alias Tisktask.Tasks
  alias Tisktask.Triggers

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_run_id" => task_run_id, "task_job_id" => task_job_id}}) do
    task_run = Tasks.get_run!(task_run_id)
    task_job = Tasks.get_job!(task_job_id)

    triggering_repository_name =
      task_run.trigger |> Triggers.repository_for!() |> Triggers.repository_name()

    triggering_sha = Triggers.head_sha(task_run.trigger)

    env_file = Tasks.Env.ensure_env_file!()

    task_run
    |> Tasks.env_for()
    |> Map.merge(Triggers.env_for(task_run.trigger))
    |> then(fn mapped -> Tasks.Env.write_env_to(env_file, mapped) end)

    Triggers.update_remote_status(
      task_run.trigger,
      task_job.program_path,
      "pending"
    )

    command_socket = Commands.spawn_command_listeners(task_run)

    {_, exit_status} =
      Podman.run_job(
        "localhost/#{triggering_repository_name}:#{triggering_sha}",
        task_job.program_path,
        env_file,
        command_socket,
        into: TaskLogs.stream_to(task_job)
      )

    status = if exit_status == 0, do: "success", else: "failure"

    Triggers.update_remote_status(
      task_run.trigger,
      task_job.program_path,
      status
    )

    Tasks.update_job!(task_job, %{exit_status: exit_status})

    :ok
  end
end
