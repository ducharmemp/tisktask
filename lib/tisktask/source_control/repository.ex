defmodule Tisktask.SourceControl.Repository do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "source_control_repositories" do
    field :name, :string
    field :url, :string
    field :api_token, :string, redact: true
    field :external_repository_id, :integer
    field :raw_attributes, :map

    timestamps(type: :utc_datetime)
  end

  def clone_uri(%__MODULE__{} = repository) do
    uri = URI.parse(repository.url)

    scheme =
      case uri.port do
        443 -> "https"
        _ -> "http"
      end

    uri
    |> Map.put(:scheme, scheme)
    |> Map.put(:userinfo, "x-access-token:#{repository.api_token}")
    |> URI.to_string()
  end

  def status_url(%__MODULE__{raw_attributes: %{"statuses_url" => statuses_url}}) do
    statuses_url
  end

  def status_url(%__MODULE__{} = repository) do
    repository.url
    |> URI.parse()
    |> Map.put(
      :path,
      "/api/v1/repos/#{owner_for(repository)}/#{name_for(repository)}/statuses/{sha}"
    )
    |> URI.to_string()
  end

  @doc false
  def changeset(repositories, attrs) do
    repositories
    |> cast(attrs, [:name, :url, :api_token, :external_repository_id, :raw_attributes])
    |> validate_required([:name, :url, :api_token])
  end

  defp owner_for(repository) do
    repository.url
    |> URI.parse()
    |> Map.get(:path)
    |> String.split("/")
    |> Enum.at(1)
  end

  defp name_for(repository) do
    repository.url
    |> URI.parse()
    |> Map.get(:path)
    |> String.split("/")
    |> Enum.at(2)
    |> String.replace(".git", "")
  end
end
