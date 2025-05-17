defmodule TisktaskWeb.RepositoryLive.Form do
  @moduledoc false
  use TisktaskWeb, :live_view

  alias Tisktask.SourceControl
  alias Tisktask.SourceControl.Repository

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage repository records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="repository-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:owner_and_repo]}
          type="text"
          label="Owner and Repo"
          placeholder="owner/repo"
        />
        <.input field={@form[:api_token]} type="text" label="API Token" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Repository</.button>
          <.button navigate={return_path(@return_to, @repository)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    repository = SourceControl.get_repository!(id)

    socket
    |> assign(:page_title, "Edit Repository")
    |> assign(:repository, repository)
    |> assign(:form, to_form(SourceControl.change_repository(repository)))
  end

  defp apply_action(socket, :new, _params) do
    repository = %Repository{}

    socket
    |> assign(:page_title, "New Repository")
    |> assign(:repository, repository)
    |> assign(:form, to_form(SourceControl.change_repository(repository)))
  end

  @impl true
  def handle_event("validate", %{"repository" => repository_params}, socket) do
    changeset =
      SourceControl.change_repository(socket.assigns.repository, repository_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"repository" => repository_params}, socket) do
    save_repository(socket, socket.assigns.live_action, repository_params)
  end

  defp save_repository(socket, :edit, repository_params) do
    case SourceControl.update_repository(socket.assigns.repository, repository_params) do
      {:ok, repository} ->
        {:noreply,
         socket
         |> put_flash(:info, "Repository updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, repository))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_repository(socket, :new, repository_params) do
    case SourceControl.synchronize_from_github!(
           repository_params["owner_and_repo"],
           repository_params["api_token"]
         ) do
      {:ok, repository} ->
        {:noreply,
         socket
         |> put_flash(:info, "Repository created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, repository))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _repository), do: ~p"/repositories"
  defp return_path("show", repository), do: ~p"/repositories/#{repository}"
end
