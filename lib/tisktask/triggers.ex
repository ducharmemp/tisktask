defmodule Tisktask.Triggers do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Tisktask.Repo
  alias Tisktask.SourceControl.Repository
  alias Tisktask.Triggers.Trigger

  def create_trigger(attrs \\ %{}) do
    changeset = Trigger.changeset(%Trigger{}, attrs)
    external_id = Ecto.Changeset.get_field(changeset, :repository_id)

    case find_repository(external_id) do
      nil ->
        {:error, :repository_not_found}

      repository ->
        changeset
        |> Trigger.assoc_repository(repository)
        |> Repo.insert()
    end
  end

  defp find_repository(nil), do: nil

  defp find_repository(external_id) do
    Repo.one(
      from r in Repository,
        where: r.external_repository_id == ^external_id
    )
  end

  def repository_for(%Trigger{} = trigger) do
    Repo.get(Repository, trigger.source_control_repository_id)
  end

  def repository_for!(%Trigger{} = trigger) do
    Repo.get!(Repository, trigger.source_control_repository_id)
  end

  def env_for(%Trigger{provider: "github"} = trigger) do
    repository = repository_for!(trigger)

    %{
      CI: "true",
      TISKTASK_GITHUB_EVENT: trigger.type,
      TISKTASK_GITHUB_ACTION: trigger.action,
      TISKTASK_GITHUB_SHA: head_sha(trigger),
      TISKTASK_GITHUB_REPOSITORY: repository.name
    }
  end

  def env_for(%Trigger{provider: "forgejo"} = trigger) do
    repository = repository_for!(trigger)

    %{
      CI: "true",
      TISKTASK_FORGEJO_EVENT: trigger.type,
      TISKTASK_FORGEJO_ACTION: trigger.action,
      TISKTASK_FORGEJO_SHA: head_sha(trigger),
      TISKTASK_FORGEJO_REPOSITORY: repository.name
    }
  end

  def clone_uri(%Repository{} = repo) do
    Repository.clone_uri(repo)
  end

  def repository_name(%Repository{name: name}) do
    name
  end

  def head_sha(%Trigger{} = trigger) do
    Map.get(trigger.payload, "after")
  end

  def type(%Trigger{action: nil} = trigger) do
    trigger.type
  end

  def type(%Trigger{} = trigger) do
    Path.join(trigger.type, trigger.action)
  end

  def update_remote_status(%Trigger{} = trigger, name, status) do
    repository = repository_for!(trigger)

    _response =
      [
        method: :post,
        base_url: Map.get(repository.raw_attributes, "statuses_url"),
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
