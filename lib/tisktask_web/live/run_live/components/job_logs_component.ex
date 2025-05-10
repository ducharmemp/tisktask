defmodule TisktaskWeb.Live.RunLive.Components.JobLogsComponent do
  @moduledoc false
  use TisktaskWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="collapse border bg-base-100 border-base-300 my-2">
      <input type="checkbox" />
      <div class="collapse-title">
        {@job.program_path}
      </div>
      <div
        class="collapse-content mockup-code w-256 max-h-256 overflow-scroll"
        id={"job-logs-#{@job.id}"}
        phx-update="stream"
      >
        <pre :for={{id, line} <- @streams.logs} id={id}><code>{line.log}</code></pre>
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
     |> stream(:logs, logs)
     |> push_event("scroll_to_bottom", %{id: "job-logs-#{assigns.job.id}"})}
  end
end
