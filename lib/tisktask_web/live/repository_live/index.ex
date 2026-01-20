defmodule TisktaskWeb.RepositoryLive.Index do
  @moduledoc false
  use TisktaskWeb, :live_view

  alias Tisktask.SourceControl

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Source control repository
        <:actions>
          <.button variant="primary" navigate={~p"/repositories/new"}>
            <.icon name="hero-plus" /> New Repository
          </.button>
        </:actions>
      </.header>

      <.table
        id="repositories"
        rows={@streams.repositories}
        row_click={fn {_id, repository} -> JS.navigate(~p"/repositories/#{repository}") end}
      >
        <:col :let={{_id, repository}} label="Name">{repository.name}</:col>
        <:col :let={{_id, repository}} label="Url">{repository.url}</:col>
        <:action :let={{_id, repository}}>
          <div class="sr-only">
            <.link navigate={~p"/repositories/#{repository}"}>Show</.link>
          </div>
          <.link navigate={~p"/repositories/#{repository}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, repository}}>
          <.link
            phx-click={JS.push("delete", value: %{id: repository.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Source control repository")
     |> stream(:repositories, SourceControl.list_repositories())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    repository = SourceControl.get_repository!(id)
    {:ok, _} = SourceControl.delete_repository(repository)

    {:noreply, stream_delete(socket, :repositories, repository)}
  end
end
