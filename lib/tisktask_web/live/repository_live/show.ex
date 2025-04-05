defmodule TisktaskWeb.RepositoryLive.Show do
  @moduledoc false
  use TisktaskWeb, :live_view

  alias Tisktask.SourceControl

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Repository {@repository.id}
        <:subtitle>This is a repository record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/repositories"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/repositories/#{@repository}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit repository
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@repository.name}</:item>
        <:item title="Url">{@repository.url}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Repository")
     |> assign(:repository, SourceControl.get_repository!(id))}
  end
end
