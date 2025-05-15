defmodule Tisktask.Tasks do
  @moduledoc """
  The Tasks context.
  """

  use Tisktask.PubSub

  import Ecto.Query, warn: false

  alias Tisktask.Repo
  alias Tisktask.SourceControl.Event
  alias Tisktask.Tasks.Job
  alias Tisktask.Tasks.Run

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
    |> publish("created")
    |> tap(fn {:ok, run} ->
      %{task_run_id: run.id} |> Workers.TaskRunWorker.new() |> Oban.insert!()
    end)
  end

  def update_run(%Run{} = run, attrs) do
    run
    |> Run.changeset(attrs)
    |> Repo.update()
    |> publish("updated")
  end

  def update_run!(%Run{} = run, attrs) do
    run
    |> Run.changeset(attrs)
    |> Repo.update!()
    |> publish("updated")
  end

  def update_job!(%Job{} = job, attrs) do
    job
    |> Job.changeset(attrs)
    |> Repo.update!()
    |> publish("updated")
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

    %Job{}
    |> Job.changeset(Map.put_new(attrs, :log_file, log_file_path))
    |> Ecto.Changeset.put_assoc(:parent_run, run)
    |> Repo.insert!()
    |> publish("created")
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
