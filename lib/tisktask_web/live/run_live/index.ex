defmodule TisktaskWeb.RunLive.Index do
  @moduledoc false
  use TisktaskWeb, :live_view

  alias Tisktask.Tasks

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
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
            <div>{run.updated_at}</div>
          </div>
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
    Tasks.subscribe_all()

    {:ok,
     socket
     |> assign(:page_title, "Listing Task runs")
     |> stream(:tasks, Tasks.list_task_runs())}
  end

  @impl true
  def handle_info({:task_run_created, task_run}, socket) do
    {:noreply, stream_insert(socket, :tasks, task_run, at: 0)}
  end

  @impl true
  def handle_info({:task_run_updated, task_run}, socket) do
    {:noreply, stream_insert(socket, :tasks, task_run)}
  end
end
