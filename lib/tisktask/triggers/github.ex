defmodule Tisktask.Triggers.Github do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "github_triggers" do
    field :type, :string
    field :action, :string
    field :payload, :map
    field :github_repository_id, :integer, virtual: true
    belongs_to :source_control_repository, GithubRepository
    timestamps()
  end

  def changeset(github_trigger, attrs) do
    github_trigger
    |> cast(attrs, [:type, :action, :payload])
    |> validate_required([:type, :payload])
  end

  def attrs_from_event(headers, payload) do
    %{
      type: Map.get(headers, "x-github-event"),
      action: Map.get(payload, "action"),
      payload: payload,
      github_repository_id: Map.get(payload, "repository", %{})["id"]
    }
  end
end
