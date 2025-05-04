defmodule TisktaskWeb.Triggers.GithubController do
  use TisktaskWeb, :controller

  alias Tisktask.Triggers
  alias Tisktask.SourceControl.Event

  action_fallback(TisktaskWeb.FallbackController)

  def create(%{req_headers: headers} = conn, payload) do
    event =
      SourceControl.EventBuilder.build(
        "github",
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
