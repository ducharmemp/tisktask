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
end
