defmodule TisktaskWeb.Triggers.ForgejoController do
  use TisktaskWeb, :controller

  alias Tisktask.Triggers

  action_fallback(TisktaskWeb.FallbackController)

  def create(%{req_headers: headers} = conn, payload) do
    forgejo_attrs =
      Triggers.Forgejo.attrs_from_event(
        Map.new(headers),
        payload
      )

    with {:ok, trigger} <- Triggers.create_forgejo_trigger(forgejo_attrs) do
      Tisktask.Tasks.create_run(trigger)

      conn
      |> put_status(:created)
      |> json(%{
        id: trigger.id
      })
    end
  end
end
