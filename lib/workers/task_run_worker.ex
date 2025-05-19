defmodule Workers.TaskRunWorker do
  @moduledoc false
  use Oban.Worker, queue: :default, max_attempts: 1

  alias Tisktask.Commands
  alias Tisktask.Containers.Buildah
  alias Tisktask.Containers.Podman
  alias Tisktask.Filesystem
  alias Tisktask.Git
  alias Tisktask.SourceControl
  alias Tisktask.TaskLogs
  alias Tisktask.Tasks
  alias Tisktask.TaskSupervisor
  alias Tisktask.Triggers

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_run_id" => task_run_id}}) do
    {:ok, build_context} = Briefly.create(type: :directory)
    task_run = Tasks.get_run!(task_run_id)
    triggering_repository = Triggers.repository_for!(task_run.github_trigger)
    triggering_sha = Triggers.head_sha(task_run.github_trigger)
    triggering_repository_name = Triggers.repository_name(triggering_repository)

    Tasks.start_run!(task_run)

    env_file = Tasks.Env.ensure_env_file!()

    task_run
    |> Tasks.env_for()
    |> Map.merge(Triggers.env_for(task_run.github_trigger))
    |> then(fn mapped -> Tasks.Env.write_env_to(env_file, mapped) end)

    triggering_repository
    |> Triggers.clone_uri()
    |> Git.clone_at(triggering_sha, build_context, into: TaskLogs.stream_to(task_run))

    Git.checkout(triggering_sha, build_context, into: TaskLogs.stream_to(task_run))

    all_jobs_to_run =
      Filesystem.all_jobs_for(build_context, Triggers.type(task_run.github_trigger))

    build_file =
      Filesystem.build_file_for(build_context, Triggers.type(task_run.github_trigger))

    Buildah.build_image(
      build_context,
      build_file,
      "#{triggering_repository_name}:#{triggering_sha}",
      into: TaskLogs.stream_to(task_run)
    )

    all_jobs = Enum.map(all_jobs_to_run, &Tasks.create_job!(task_run, %{program_path: &1}))

    all_job_results =
      Tisktask.TaskSupervisor
      |> Task.Supervisor.async_stream_nolink(
        all_jobs,
        &run_child_job(
          &1,
          task_run,
          "localhost/#{triggering_repository_name}:#{triggering_sha}",
          env_file
        ),
        ordered: true,
        timeout: :infinity
      )
      |> Enum.to_list()

    Tasks.complete_run!(task_run)

    :ok
  end

  defp run_child_job(child_job, task_run, image_name, env_file) do
    Triggers.update_remote_status(
      task_run.github_trigger,
      child_job.program_path,
      "pending"
    )

    command_socket = Commands.spawn_command_listeners()

    {_, exit_status} =
      Tisktask.Podman.run_job(
        image_name,
        child_job.program_path,
        env_file,
        command_socket,
        into: Tisktask.TaskLogs.stream_to(child_job)
      )

    status = if exit_status == 0, do: "success", else: "failure"

    Triggers.update_remote_status(
      task_run.github_trigger,
      child_job.program_path,
      status
    )

    Tasks.update_job!(child_job, %{exit_status: exit_status})
  end
end
