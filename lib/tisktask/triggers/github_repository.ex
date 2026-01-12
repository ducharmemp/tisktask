defmodule Tisktask.Triggers.GithubRepository do
  @moduledoc false
  use Ecto.Schema

  schema "source_control_repositories" do
    field :name, :string
    field :url, :string
    field :api_token, :string, redact: true
    field :external_repository_id, :integer
    field :raw_attributes, :map

    timestamps(type: :utc_datetime)
  end

  def clone_uri(%__MODULE__{} = repository) do
    repository.url
    |> URI.parse()
    |> Map.put(:scheme, "https")
    |> Map.put(:userinfo, "x-access-token:#{repository.api_token}")
    |> URI.to_string()
  end
end
