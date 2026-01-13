defmodule TisktaskWeb.Triggers.ForgejoController do
  use TisktaskWeb, :controller

  alias Tisktask.Triggers
  alias Tisktask.Triggers.Trigger

  action_fallback(TisktaskWeb.FallbackController)

  def create(%{req_headers: headers} = conn, payload) do
    trigger_attrs =
      Trigger.attrs_from_forgejo_event(
        Map.new(headers),
        payload
      )

    with {:ok, trigger} <- Triggers.create_trigger(trigger_attrs) do
      Tisktask.Tasks.create_run(trigger)

      conn
      |> put_status(:created)
      |> json(%{
        id: trigger.id
      })
    end
  end
end
