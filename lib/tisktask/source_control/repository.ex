defmodule Tisktask.SourceControl.Repository do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "source_control_repositories" do
    field :name, :string
    field :url, :string
    field :api_token, :string, redact: true

    has_one(:github_repository_attributes, Tisktask.SourceControl.GithubRepositoryAttributes,
      foreign_key: :source_control_repository_id
    )

    timestamps(type: :utc_datetime)
  end

  def clone_uri(%__MODULE__{} = repository) do
    repository.url
    |> URI.parse()
    |> Map.put(:scheme, "http")
    |> Map.put(:userinfo, "x-access-token:#{repository.api_token}")
    |> URI.to_string()
  end

  def status_uri(%__MODULE__{} = repository, sha) do
    repository.url
    |> URI.parse()
    |> Map.put(:scheme, "http")
    |> Map.put(
      :path,
      "/api/v1/repos/#{owner_for(repository)}/#{name_for(repository)}/statuses/#{sha}"
    )
  end

  @doc false
  def changeset(repositories, attrs) do
    repositories
    |> cast(attrs, [:name, :url, :api_token])
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
