defmodule Tisktask.Triggers.Trigger do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Tisktask.SourceControl.Repository

  schema "triggers" do
    field :provider, :string
    field :type, :string
    field :action, :string
    field :payload, :map
    field :repository_id, :integer, virtual: true
    belongs_to :source_control_repository, Repository
    timestamps()
  end

  def changeset(trigger, attrs) do
    trigger
    |> cast(attrs, [:provider, :type, :action, :payload, :repository_id])
    |> validate_required([:provider, :type, :payload])
    |> validate_inclusion(:provider, ["github", "forgejo"])
  end

  def assoc_repository(%Ecto.Changeset{} = changeset, %Repository{} = repository) do
    put_assoc(changeset, :source_control_repository, repository)
  end

  def attrs_from_github_event(headers, payload) do
    %{
      provider: "github",
      type: Map.get(headers, "x-github-event"),
      action: Map.get(payload, "action"),
      payload: payload,
      repository_id: Map.get(payload, "repository", %{})["id"]
    }
  end

  def attrs_from_forgejo_event(headers, payload) do
    %{
      provider: "forgejo",
      type: Map.get(headers, "x-forgejo-event"),
      action: Map.get(payload, "action"),
      payload: payload,
      repository_id: Map.get(payload, "repository", %{})["id"]
    }
  end
end
