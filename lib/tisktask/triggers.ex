defmodule Tisktask.Triggers do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Tisktask.Repo
  alias Tisktask.Triggers.Forgejo
  alias Tisktask.Triggers.Github
  alias Tisktask.Triggers.GithubRepository
  alias Tisktask.Triggers.GithubRepositoryAttributes

  def create_github_trigger(attrs \\ %{}) do
    with {:ok, trigger} <- Github.changeset(%Github{}, attrs),
         repository = repository_for(trigger),
         {:ok, _} <- trigger |> Github.assoc_repository(repository) |> Repo.insert() do
      {:ok, trigger}
    end
  end

  def create_forgejo_trigger(attrs \\ %{}) do
    with {:ok, trigger} <- Forgejo.changeset(%Forgejo{}, attrs),
         repository = repository_for(trigger),
         {:ok, _} <- trigger |> Forgejo.assoc_repository(repository) |> Repo.insert() do
      {:ok, trigger}
    end
  end

  def repository_for(%Github{github_repository_id: nil} = trigger) do
    Repo.get(GithubRepository, trigger.source_control_repository_id)
  end

  def repository_for!(%Github{github_repository_id: nil} = trigger) do
    Repo.get!(GithubRepository, trigger.source_control_repository_id)
  end

  def repository_for(%Github{github_repository_id: github_repository_id}) do
    Repo.one(
      from r in GithubRepository,
        join: a in GithubRepositoryAttributes,
        on: a.source_control_repository_id == r.id,
        where: a.github_repository_id == ^github_repository_id
    )
  end

  def repository_for!(%Github{github_repository_id: github_repository_id}) do
    Repo.one!(
      from r in GithubRepository,
        join: a in GithubRepositoryAttributes,
        on: a.source_control_repository_id == r.id,
        where: a.github_repository_id == ^github_repository_id
    )
  end

  def env_for(%Github{} = trigger) do
    repository = repository_for!(trigger)

    %{
      CI: "true",
      TISKTASK_GITHUB_EVENT: trigger.type,
      TISKTASK_GITHUB_ACTION: trigger.action,
      TISKTASK_GITHUB_SHA: head_sha(trigger),
      TISKTASK_GITHUB_REPOSITORY: repository.name
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
      |> Keyword.merge(Application.get_env(:tisktask, :trigger_remote_status_options, []))
      |> Req.request!()
  end
end
