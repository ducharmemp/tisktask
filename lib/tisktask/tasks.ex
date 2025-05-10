defmodule Tisktask.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false

  alias Tisktask.Repo
  alias Tisktask.SourceControl.Event
  alias Tisktask.Tasks.Job
  alias Tisktask.Tasks.Run

  def subscribe_all do
    Phoenix.PubSub.subscribe(Tisktask.PubSub, "task_run")
  end

  def subscribe_to(%Run{} = run) do
    Phoenix.PubSub.subscribe(Tisktask.PubSub, "task_run#{run.id}")
  end

  def subscribe_to(%Job{} = job) do
    Phoenix.PubSub.subscribe(Tisktask.PubSub, "task_job#{job.id}")
  end

  def list_task_runs do
    all_task_runs_query() |> Repo.all() |> Repo.preload(:github_trigger)
  end

  def get_run!(id), do: all_task_runs_query() |> Repo.get!(id) |> Repo.preload(:github_trigger)

  def preload_task_jobs(run) do
    Repo.preload(run, :jobs)
  end

  def create_run(trigger) do
    log_file_path = Tisktask.TaskLogs.ensure_log_file!()
    attrs = %{log_file: log_file_path, status: :staged}

    %Run{}
    |> Run.changeset(attrs)
    |> Run.trigger_from(trigger)
    |> Repo.insert()
    |> tap(fn {:ok, run} ->
      %{task_run_id: run.id} |> Workers.TaskRunWorker.new() |> Oban.insert!()
      Phoenix.PubSub.broadcast(Tisktask.PubSub, "task_run", {:task_run_created, run})
    end)
  end

  def update_run(%Run{} = run, attrs) do
    run
    |> Run.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, run} ->
        run = get_run!(run.id)

        Phoenix.PubSub.broadcast(
          Tisktask.PubSub,
          "task_run",
          {:task_run_updated, get_run!(run.id)}
        )

        Phoenix.PubSub.broadcast(
          Tisktask.PubSub,
          "task_run#{run.id}",
          {:task_run_updated, get_run!(run.id)}
        )

        {:ok, run}

      error ->
        error
    end
  end

  def update_run!(%Run{} = run, attrs) do
    run
    |> Run.changeset(attrs)
    |> Repo.update!()
    |> tap(fn run ->
      Phoenix.PubSub.broadcast(Tisktask.PubSub, "task_run", {:task_run_updated, get_run!(run.id)})
    end)
  end

  def update_job!(%Job{} = job, attrs) do
    job
    |> Job.changeset(attrs)
    |> Repo.update!()
    |> tap(fn job ->
      Phoenix.PubSub.broadcast(Tisktask.PubSub, "task_job", {:task_job_updated, job})
      Phoenix.PubSub.broadcast(Tisktask.PubSub, "task_job#{job.id}", {:task_job_updated, job})
    end)
  end

  def change_run(%Run{} = run, attrs \\ %{}) do
    Run.changeset(run, attrs)
  end

  def complete_run!(%Run{} = run) do
    update_run!(run, %{status: "completed"})
  end

  def start_run!(%Run{} = run) do
    update_run!(run, %{status: "running"})
  end

  def create_job!(%Run{} = run, attrs \\ %{}) do
    log_file_path = Tisktask.TaskLogs.ensure_log_file!()

    child_job =
      %Job{}
      |> Job.changeset(Map.put_new(attrs, :log_file, log_file_path))
      |> Ecto.Changeset.put_assoc(:parent_run, run)
      |> Repo.insert!()

    Phoenix.PubSub.broadcast(Tisktask.PubSub, "task_job", {:task_job_created, child_job})

    Phoenix.PubSub.broadcast(
      Tisktask.PubSub,
      "task_run#{run.id}",
      {:task_job_created, child_job}
    )

    child_job
  end

  defp all_task_runs_query do
    from r in Run,
      left_join: j in subquery(failed_jobs_per_run_query()),
      on: r.id == j.task_run_id,
      select: %{
        r
        | any_jobs_failed?: coalesce(j.count, 0) > 0
      },
      order_by: [desc: r.inserted_at]
  end

  defp failed_jobs_per_run_query do
    from j in Job,
      group_by: j.task_run_id,
      where: j.exit_status != 0,
      select: %{task_run_id: j.task_run_id, count: count(j)}
  end
end
