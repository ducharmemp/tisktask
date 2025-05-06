defmodule TisktaskWeb.RunLive.Form do
  @moduledoc false
  use TisktaskWeb, :live_view

  alias Tisktask.Tasks
  alias Tisktask.Tasks.Run

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage run records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="run-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:api_token]} type="text" label="Url" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save run</.button>
          <.button navigate={return_path(@return_to, @run)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, "index")
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    run = %Run{}

    socket
    |> assign(:page_title, "New Run")
    |> assign(:run, run)
    |> assign(:form, to_form(Tasks.change_run(run)))
  end

  @impl true
  def handle_event("validate", %{"run" => run_params}, socket) do
    changeset =
      Tasks.change_run(socket.assigns.run, run_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"run" => run_params}, socket) do
    save_run(socket, socket.assigns.live_action, run_params)
  end

  defp save_run(socket, :edit, run_params) do
    case Tasks.update_run(socket.assigns.run, run_params) do
      {:ok, run} ->
        {:noreply,
         socket
         |> put_flash(:info, "run updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, run))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_run(socket, :new, run_params) do
    case Tasks.create_run(run_params) do
      {:ok, run} ->
        {:noreply,
         socket
         |> put_flash(:info, "run created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, run))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _run), do: ~p"/tasks"
end
