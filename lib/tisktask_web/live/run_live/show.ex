defmodule TisktaskWeb.RunLive.Show do
  @moduledoc false
  use TisktaskWeb, :live_view

  alias Tisktask.Tasks
  alias Tisktask.Tasks.Job
  alias Tisktask.Tasks.Run
  alias TisktaskWeb.Live.RunLive.Components.JobLogsComponent
  alias TisktaskWeb.Live.RunLive.Components.RunLogsComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Run {@run.id}
        <:subtitle>
          <.icon name="hero-arrow-right" />
          {@run.status}
        </:subtitle>
        <:actions>
          <.button navigate={~p"/tasks"}>
            <.icon name="hero-arrow-left" />
          </.button>
        </:actions>
      </.header>

      <div>
        <div>
          <h4 class="text-lg font-semibold pb-2">Setup Logs</h4>
          <.live_component
            module={TisktaskWeb.Live.RunLive.Components.RunLogsComponent}
            id={log_id_for(@run)}
            run={@run}
          />
        </div>
        <div>
          <h4 class="text-lg font-semibold py-2">Job Logs</h4>
          <div id="job-logs" phx-update="stream">
            <span :for={{id, job} <- @streams.task_jobs} id={id}>
              <.live_component
                module={TisktaskWeb.Live.RunLive.Components.JobLogsComponent}
                id={log_id_for(job)}
                job={job}
              />
            </span>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    task_run = id |> Tasks.get_run!() |> Tasks.preload_task_jobs()
    Tisktask.Tasks.subscribe_to(task_run)
    Tisktask.TaskLogs.subscribe_to(task_run)

    for job <- task_run.jobs do
      Tisktask.TaskLogs.subscribe_to(job)
      Tisktask.Tasks.subscribe_to(job)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Run")
     |> assign(:run, task_run)
     |> stream(:task_jobs, task_run.jobs)}
  end

  @impl true
  def handle_info({:task_run_updated, %Run{id: id} = run}, socket) do
    send_update(
      RunLogsComponent,
      id: log_id_for(run),
      run: run
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:task_job_created, job}, socket) do
    Tisktask.Tasks.subscribe_to(job)
    Tisktask.TaskLogs.subscribe_to(job)

    {:noreply, stream_insert(socket, :task_jobs, job)}
  end

  @impl true
  def handle_info({:task_job_updated, %Job{id: id} = job, log}, socket) do
    send_update(
      JobLogsComponent,
      id: log_id_for(job),
      job: job
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:log, %Run{id: id} = run, log}, socket) do
    send_update(
      RunLogsComponent,
      id: log_id_for(run),
      run: run,
      log: log
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:log, %Job{id: id} = job, log}, socket) do
    send_update(
      JobLogsComponent,
      id: log_id_for(job),
      job: job,
      log: log
    )

    {:noreply, socket}
  end

  defp log_id_for(%Job{} = job) do
    "task_job_#{job.id}"
  end

  defp log_id_for(%Run{} = run) do
    "task_run_#{run.id}"
  end
end
