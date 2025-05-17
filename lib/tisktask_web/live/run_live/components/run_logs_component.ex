defmodule TisktaskWeb.Live.RunLive.Components.RunLogsComponent do
  @moduledoc false
  use TisktaskWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="collapse border bg-base-100 border-base-300 my-2">
      <input type="checkbox" phx-click="toggle_logs" checked={@logs_open} phx-target={@myself} />
      <div class="collapse-title flex flex-row gap-2">
        <.icon :if={@run.status == :completed} name="hero-check" class="text-green-400" />
        <div
          :if={@run.status != :completed}
          name=""
          class="loading loading-dots loading-md text-yellow-400"
        />
        <div>Pre-Run Setup for #{@run.id}</div>
      </div>
      <div
        class="collapse-content bg-neutral text-neutral-content w-256 max-h-256 overflow-scroll"
        id={"run-logs-#{@run.id}"}
        phx-update="stream"
      >
        <pre :for={{id, line} <- @streams.logs} id={"#{@run.id}-#{id}"}><code>{line.log}</code></pre>
      </div>
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
     |> assign(:logs_open, false)
     |> stream(:logs, logs)
     |> push_event("scroll_to_bottom", %{id: "run-logs-#{assigns.run.id}"})}
  end

  def handle_event("toggle_logs", _params, socket) do
    {:noreply, assign(socket, :logs_open, !socket.assigns.logs_open)}
  end
end
