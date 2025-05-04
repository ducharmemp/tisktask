defmodule Workers.TaskRunWorker do
  @moduledoc false
  use Oban.Worker, queue: :default, max_attempts: 1

  alias Tisktask.Buildah
  alias Tisktask.Filesystem
  alias Tisktask.Git
  alias Tisktask.Podman
  alias Tisktask.SourceControl
  alias Tisktask.TaskLogs
  alias Tisktask.Tasks
  alias Tisktask.TaskSupervisor

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_run_id" => task_run_id}}) do
    {:ok, build_context} = Briefly.create(type: :directory)

    task_run =
      task_run_id |> Tasks.get_run!() |> Tisktask.Repo.preload(event: [:repo])

    Tasks.start_run!(task_run)

    clone_repo_uri = Tisktask.SourceControl.Repository.clone_uri(task_run.event.repo)

    Git.clone_into(clone_repo_uri, build_context, task_run.event.head_sha, into: TaskLogs.stream_to(task_run))

    Git.checkout(build_context, task_run.event.head_sha, into: TaskLogs.stream_to(task_run))
    all_jobs_to_run = Filesystem.all_jobs_for(build_context, task_run.event.type)
    build_file = Filesystem.build_file_for(build_context, task_run.event.type)

    Buildah.build_image(
      build_context,
      build_file,
      "#{task_run.event.repo.name}:#{task_run.event.head_sha}",
      into: TaskLogs.stream_to(task_run)
    )

    all_jobs = Enum.map(all_jobs_to_run, &Tasks.create_job!(task_run, %{program_path: &1}))

    all_job_results =
      Tisktask.TaskSupervisor
      |> Task.Supervisor.async_stream_nolink(
        all_jobs,
        &run_child_job(&1, task_run),
        ordered: true,
        timeout: :infinity
      )
      |> Enum.to_list()

    Tasks.complete_run!(task_run)

    :ok
  end

  defp run_child_job(child_job, task_run) do
    # SourceControl.create_commit_status!(
    #   task_run.event,
    #   task_run.event.type,
    #   child_job.program_path,
    #   "pending"
    # )

    {_, exit_status} =
      Tisktask.Podman.run_job(
        "localhost/#{task_run.event.repo.name}:#{task_run.event.head_sha}",
        child_job.program_path,
        into: Tisktask.TaskLogs.stream_to(child_job)
      )

    Tasks.update_job!(child_job, %{exit_status: exit_status})

    # SourceControl.create_commit_status!(
    #   task_run.event,
    #   task_run.event.type,
    #   child_job.program_path,
    #   "success"
    # )
  end
end
