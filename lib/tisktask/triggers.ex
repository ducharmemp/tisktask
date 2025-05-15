defmodule Tisktask.Triggers do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Tisktask.Repo
  alias Tisktask.Triggers.Github
  alias Tisktask.Triggers.GithubRepository
  alias Tisktask.Triggers.GithubRepositoryAttributes

  def create_github_trigger(attrs \\ %{}) do
    %Github{}
    |> Github.changeset(attrs)
    |> Repo.insert()
  end

  def repository_for!(%Github{} = trigger) do
    Repo.one!(
      from r in GithubRepository,
        join: a in GithubRepositoryAttributes,
        where: a.github_repository_id == ^trigger.github_repository_id,
        select: r
    )
  end

  def env_for(%GithubRepository{} = repository, %Github{} = trigger) do
    %{
      CI: "true",
      TISKTASK_GITHUB_EVENT: trigger.type,
      TISKTASK_GITHUB_ACTION: trigger.action,
      TISKTASK_GITHUB_SHA: head_sha(trigger),
      TISKTASK_GITHUB_REPOSITORY: repository.name,
    }
  end

  def clone_uri(%GithubRepository{} = repo) do
    GithubRepository.clone_uri(repo)
  end

  def repository_name(%GithubRepository{name: name}) do
    name
  end

  def head_sha(%Github{} = trigger) do
    Map.get(trigger.payload, "after")
  end

  def type(%Github{} = trigger) do
    Path.join(trigger.type, trigger.action)
  end

  def update_remote_status(%Github{} = trigger, name, status) do
    repository = trigger |> repository_for!() |> Repo.preload(:github_repository_attributes)

    response =
      [
        method: :post,
        base_url: Map.get(repository.github_repository_attributes.raw_attributes, "statuses_url"),
        path_params: [
          sha: head_sha(trigger)
        ],
        path_params_style: :curly,
        auth: {:bearer, repository.api_token},
        json: %{
          state: status,
          target_url: "https://example.com/build/status",
          description: "Test description",
          context: name
        }
      ]
      |> Keyword.merge(Application.get_env(:tisktask, :github_req_options, []))
      |> Req.request!()
  end
end
