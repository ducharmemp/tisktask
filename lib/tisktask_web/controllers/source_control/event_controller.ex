defmodule TisktaskWeb.SourceControl.EventController do
  use TisktaskWeb, :controller

  alias Tisktask.SourceControl
  alias Tisktask.SourceControl.Event

  action_fallback(TisktaskWeb.FallbackController)

  def index(conn, _params) do
    source_control_events = SourceControl.list_source_control_events()
    render(conn, :index, source_control_events: source_control_events)
  end

  def create(%{path_params: path_params, req_headers: headers} = conn, payload) do
    event =
      SourceControl.EventBuilder.build(
        Map.get(path_params, "originator"),
        Map.new(headers),
        payload
      )

    with {:ok, %Event{} = event} <- event do
      Tisktask.Tasks.stage_task_run(event)

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/source_control/events/#{event}")
      |> render(:show, event: event)
    end
  end

  def show(conn, %{"id" => id}) do
    event = SourceControl.get_event!(id)
    render(conn, :show, event: event)
  end
end
