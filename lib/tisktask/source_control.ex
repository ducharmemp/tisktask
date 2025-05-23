defmodule Tisktask.SourceControl do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Tisktask.Repo
  alias Tisktask.SourceControl.GithubRepositoryAttributes
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

  def create_github_attributes(attrs \\ %{}, source_control_repository) do
    %GithubRepositoryAttributes{}
    |> GithubRepositoryAttributes.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:source_control_repository, source_control_repository)
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

  def synchronize_from_github!(owner_and_repo, api_token) do
    [owner, repo] = String.split(owner_and_repo, "/")
    response = execute_github_request!(owner, repo, api_token)
    name = Map.get(response, "name")
    clone_url = Map.get(response, "clone_url")
    github_repository_id = Map.get(response, "id")

    with {:ok, repository} <-
           create_repository(%{name: name, url: clone_url, api_token: api_token}),
         {:ok, _} <-
           create_github_attributes(
             %{
               raw_attributes: response,
               github_repository_id: github_repository_id
             },
             repository
           ) do
      {:ok, repository}
    end
  end

  defp execute_github_request!(owner, repo, api_token) do
    response =
      [
        base_url: "https://api.github.com/repos/:owner/:repo",
        path_params: [
          owner: owner,
          repo: repo
        ],
        auth: {:bearer, api_token}
      ]
      |> Keyword.merge(Application.get_env(:tisktask, :github_req_options, []))
      |> Req.request!()

    response.body
  end
end
