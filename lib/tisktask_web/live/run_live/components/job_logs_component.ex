defmodule TisktaskWeb.Live.RunLive.Components.JobLogsComponent do
  @moduledoc false
  use TisktaskWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="collapse border bg-base-100 border-base-300 my-2">
      <input
        type="checkbox"
        phx-click="toggle_logs"
        name="open"
        phx-target={@myself}
        checked={@logs_open}
      />
      <div class="collapse-title flex flex-row gap-2">
        <.icon
          :if={@job.exit_status != 0 && is_number(@job.exit_status)}
          name="hero-x-mark"
          class="text-red-400"
        />
        <.icon :if={@job.exit_status == 0} name="hero-check" class="text-green-400" />
        <div
          :if={@job.exit_status != 0 && is_nil(@job.exit_status)}
          name=""
          class="loading loading-dots loading-md text-yellow-400"
        />
        <div>
          {@job.program_path}
        </div>
      </div>
      <div
        class="collapse-content bg-neutral text-neutral-content w-256 max-h-256 overflow-scroll"
        id={"job-logs-#{@job.id}"}
        phx-update="stream"
      >
        <pre :for={{id, line} <- @streams.logs} id={"#{@job.id}-#{id}"}><code>{line.log}</code></pre>
      </div>
    </div>
    """
  end

  def update(%{job: job, log: log}, socket) do
    {:ok,
     socket
     |> stream_insert(:logs, log)
     |> push_event("scroll_to_bottom", %{id: "job-logs-#{job.id}"})}
  end

  def update(assigns, socket) do
    logs = Tisktask.TaskLogs.stream_from!(assigns.job)

    {:ok,
     socket
     |> assign(:job, assigns.job)
     |> assign(:logs_open, false)
     |> stream(:logs, logs)
     |> push_event("scroll_to_bottom", %{id: "job-logs-#{assigns.job.id}"})}
  end

  def handle_event("toggle_logs", _params, socket) do
    {:noreply, assign(socket, :logs_open, !socket.assigns.logs_open)}
  end
end
