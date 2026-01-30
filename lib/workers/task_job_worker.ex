defmodule Workers.TaskJobWorker do
  @moduledoc false
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Tisktask.Tasks.Runner

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_run_id" => task_run_id, "task_job_id" => task_job_id}}) do
    {:ok, pid} = Runner.start_link(task_run_id: task_run_id, task_job_id: task_job_id)

    case Runner.run(pid) do
      {:ok, _exit_status} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
