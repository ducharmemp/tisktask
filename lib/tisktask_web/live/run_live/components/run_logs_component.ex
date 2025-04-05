defmodule TisktaskWeb.Live.RunLive.Components.RunLogsComponent do
  @moduledoc false
  use TisktaskWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      class="mockup-code w-256 h-256 max-h-256 overflow-scroll"
      id={"run-logs-#{@run.id}"}
      phx-update="stream"
    >
      <pre :for={{id, line} <- @streams.logs} id={id}><code>{line.log}</code></pre>
    </div>
    """
  end

  def update(%{run: run, log: log} = assigns, socket) do
    {:ok,
     socket
     |> stream_insert(:logs, log)
     |> push_event("scroll_to_bottom", %{id: "run-logs-#{run.id}"})}
  end

  def update(assigns, socket) do
    logs = Tisktask.TaskLogs.stream_from!(assigns.run)

    {:ok,
     socket
     |> assign(:run, assigns.run)
     |> stream(:logs, logs)
     |> push_event("scroll_to_bottom", %{id: "run-logs-#{assigns.run.id}"})}
  end
end
