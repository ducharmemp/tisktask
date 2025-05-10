defmodule TisktaskWeb.Triggers.GithubController do
  use TisktaskWeb, :controller

  alias Tisktask.Triggers

  action_fallback(TisktaskWeb.FallbackController)

  def create(%{req_headers: headers} = conn, payload) do
    github_attrs =
      Triggers.Github.attrs_from_event(
        Map.new(headers),
        payload
      )

    with {:ok, trigger} <- Triggers.create_github_trigger(github_attrs) do
      Tisktask.Tasks.create_run(trigger)

      conn
      |> put_status(:created)
      |> json(%{
        message: "run triggered"
      })
    end
  end
end
