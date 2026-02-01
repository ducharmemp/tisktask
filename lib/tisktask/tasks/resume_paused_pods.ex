defmodule Tisktask.Tasks.ResumePausedPods do
  @moduledoc """
  Startup task that resumes any pods that were paused due to SIGINT.

  On application startup, this process:
  1. Queries podman for paused pods
  2. Matches each pod to its task_job via the stored pod_id
  3. Spawns Runners in resume mode to continue the interrupted jobs
  """

  use Task, restart: :temporary

  require Logger

  alias Tisktask.Containers.Podman
  alias Tisktask.Tasks
  alias Tisktask.Tasks.Runner

  def start_link(_arg) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    paused_pods = Podman.list_paused_pods()

    if paused_pods != [] do
      Logger.info("Found #{length(paused_pods)} paused pod(s) to resume")
    end

    Enum.each(paused_pods, &resume_pod/1)
  end

  defp resume_pod(pod_id) do
    case Tasks.get_job_by_pod_id(pod_id) do
      nil ->
        Logger.warning("No task_job found for paused pod #{pod_id}, skipping")

      task_job ->
        Logger.info("Resuming paused pod #{pod_id} for job #{task_job.id}")
        {:ok, pid} = Runner.start_link_resume(task_job_id: task_job.id)
        Task.Supervisor.start_child(Tisktask.TaskSupervisor, __MODULE__, :do_resume, [pid, task_job.id])
    end
  end

  @doc false
  def do_resume(pid, job_id) do
    case Runner.resume(pid) do
      {:ok, exit_status} ->
        Logger.info("Resumed job #{job_id} completed with exit status #{exit_status}")

      {:error, reason} ->
        Logger.error("Resumed job #{job_id} failed: #{inspect(reason)}")

      {:retry, reason} ->
        Logger.warning("Resumed job #{job_id} needs retry: #{inspect(reason)}")
    end
  end
end
