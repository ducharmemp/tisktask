defmodule Tisktask.SourceControl.Event do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "task_events" do
    field(:type, :string)
    field(:payload, :map)
    field(:originator, :string)
    field(:head_sha)
    field(:head_ref)
    belongs_to(:repo, Tisktask.SourceControl.Repository)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type, :payload, :originator, :head_sha, :head_ref])
    |> validate_required([:type, :originator, :head_sha, :head_ref])
  end

  def change_repo(event, repo) do
    event
    |> change()
    |> put_assoc(:repo, repo)
    |> validate_required([:repo])
  end
end
