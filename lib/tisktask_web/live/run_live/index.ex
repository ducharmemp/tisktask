defmodule TisktaskWeb.RunLive.Index do
  @moduledoc false
  use TisktaskWeb, :live_view

  alias Tisktask.Tasks

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Task runs
        <:actions>
          <.button variant="primary" navigate={~p"/tasks/new"}>
            <.icon name="hero-plus" /> New Run
          </.button>
        </:actions>
      </.header>

      <.table
        id="tasks"
        rows={@streams.tasks}
        row_click={fn {_id, run} -> JS.navigate(~p"/tasks/#{run}") end}
      >
        <:col :let={{_id, run}} label="Status">
          <div class="flex flex-row gap-2">
            <div
              :if={run.status != :completed}
              class="loading loading-dots loading-md text-yellow-400"
            >
            </div>
            <div>
              <.icon
                :if={run.status == :completed && !run.any_jobs_failed?}
                name="hero-check"
                class="text-green-400"
              />
              <.icon
                :if={run.status == :completed && run.any_jobs_failed?}
                name="hero-x-mark"
                class="text-red-400"
              />
            </div>
            <div>{run.status}</div>
          </div>
        </:col>
        <:col :let={{_id, run}} label="Repository">
          <div>{run.trigger.source_control_repository.name}</div>
        </:col>
        <:col :let={{_id, run}} label="Type">
          <div>{run.trigger.type}</div>
        </:col>
        <:col :let={{_id, run}} label="Action">
          <div>{run.trigger.action}</div>
        </:col>
        <:col :let={{_id, run}} label="Last Update">
          <div>{run.updated_at}</div>
        </:col>
        <:action :let={{_id, run}}>
          <div class="sr-only">
            <.link navigate={~p"/tasks/#{run}"}>Show</.link>
          </div>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Tasks.subscribe_to(Tisktask.Tasks.Run)

    {:ok,
     socket
     |> assign(:page_title, "Listing Task runs")
     |> stream(:tasks, Tasks.list_task_runs(), limit: 25)}
  end

  @impl true
  def handle_info({"task_runs:created", task_run_id}, socket) do
    task_run = Tasks.get_run!(task_run_id)
    {:noreply, stream_insert(socket, :tasks, task_run, at: 0, limit: 25)}
  end

  @impl true
  def handle_info({"task_runs:updated", task_run_id}, socket) do
    task_run = Tasks.get_run!(task_run_id)
    {:noreply, stream_insert(socket, :tasks, task_run)}
  end
end
