defmodule TisktaskWeb.RunLive.Show do
  @moduledoc false
  use TisktaskWeb, :live_view

  alias Tisktask.Tasks
  alias Tisktask.Tasks.Job
  alias Tisktask.Tasks.Run

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Run {@run.id}
        <:subtitle>
          <.icon name="hero-arrow-right" />
          <%= @run.status %>
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
            id="run_log_lines"
            run={@run}
          />
        </div>
        <div>
          <h4 class="text-lg font-semibold py-2">Job Logs</h4>
          <.live_component
            :for={job <- @task_jobs}
            module={TisktaskWeb.Live.RunLive.Components.JobLogsComponent}
            id={"task-job-#{job.id}"}
            job={job}
          />
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
    for job <- task_run.jobs, do: Tisktask.TaskLogs.subscribe_to(job)

    {:ok,
     socket
     |> assign(:page_title, "Show Run")
     |> assign(:run, task_run)
     |> assign(:task_jobs, task_run.jobs)}
  end

  @impl true
  def handle_info({:task_job_created, job}, socket) do
    Tisktask.TaskLogs.subscribe_to(job)

    {:noreply, assign(socket, :task_jobs, [socket.assigns.task_jobs | job])}
  end

  @impl true
  def handle_info({:log, %Run{id: id} = run, log}, socket) do
    send_update(
      TisktaskWeb.Live.RunLive.Components.RunLogsComponent,
      id: "run_log_lines",
      run: run,
      log: log
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:log, %Job{id: id} = job, log}, socket) do
    send_update(
      TisktaskWeb.Live.RunLive.Components.JobLogsComponent,
      id: "task-job-#{id}",
      job: job,
      log: log
    )

    {:noreply, socket}
  end
end
