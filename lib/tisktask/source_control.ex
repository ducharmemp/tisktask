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

  def synchronize_from_github!(owner_and_repo, api_token) do
    [owner, repo] = String.split(owner_and_repo, "/")
    response = execute_github_request!(owner, repo, api_token)
    name = Map.get(response, "name")
    clone_url = Map.get(response, "clone_url")
    github_repository_id = Map.get(response, "id")

    create_repository(%{
      name: name,
      url: clone_url,
      api_token: api_token,
      external_repository_id: github_repository_id,
      raw_attributes: response
    })
  end

  def synchronize_from_forgejo!(url, api_token) do
    uri = URI.parse(url)
    [_, owner, repo] = String.split(uri.path, "/")
    response = execute_forgejo_request!(uri, owner, repo, api_token)
    name = Map.get(response, "name")
    clone_url = Map.get(response, "clone_url")
    forgejo_repository_id = Map.get(response, "id")

    create_repository(%{
      name: name,
      url: clone_url,
      api_token: api_token,
      external_repository_id: forgejo_repository_id,
      raw_attributes: response
    })
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

  defp execute_forgejo_request!(uri, owner, repo, api_token) do
    base_url = "#{uri.scheme}://#{uri.host}#{if uri.port, do: ":#{uri.port}", else: ""}"

    response =
      [
        base_url: "#{base_url}/api/v1/repos/:owner/:repo",
        path_params: [
          owner: owner,
          repo: repo
        ],
        auth: {:bearer, api_token}
      ]
      |> Keyword.merge(Application.get_env(:tisktask, :forgejo_req_options, []))
      |> Req.request!()

    response.body
  end
end
