defmodule Tisktask.SourceControl do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Tisktask.Repo
  alias Tisktask.SourceControl.Repository

  def list_repositories do
    Repo.all(Repository)
  end

  def get_repository!(id), do: Repo.get!(Repository, id)

  def get_repository_by_url(url) do
    Repo.get_by!(Repository, url: url)
  end

  def create_repository(attrs \\ %{}) do
    %Repository{}
    |> Repository.changeset(attrs)
    |> Repo.insert()
  end

  def update_repository(%Repository{} = repository, attrs) do
    repository
    |> Repository.changeset(attrs)
    |> Repo.update()
  end

  def delete_repository(%Repository{} = repository) do
    Repo.delete(repository)
  end

  def change_repository(%Repository{} = repository, attrs \\ %{}) do
    Repository.changeset(repository, attrs)
  end

  # def create_commit_status!(%Event{} = event, context, name, state) do
  #   event.repo
  #   |> Repository.status_uri(event.head_sha)
  #   |> Req.post!(
  #     auth: "token #{event.repo.api_token}",
  #     json: %{
  #       state: state,
  #       description: name,
  #       context: context,
  #       target_url: "https://example.com"
  #     }
  #   )
  # end
end
