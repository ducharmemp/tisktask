defmodule Tisktask.SourceControl.GithubRepositoryAttributes do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "github_repository_attributes" do
    field :github_repository_id, :integer

    belongs_to :source_control_repository, Tisktask.SourceControl.Repository,
      foreign_key: :source_control_repository_id

    field :raw_attributes, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(github_repository_attributes, attrs) do
    github_repository_attributes
    |> cast(attrs, [:github_repository_id, :raw_attributes])
    |> validate_required([:github_repository_id, :raw_attributes])
  end
end
