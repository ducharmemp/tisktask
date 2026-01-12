defmodule Tisktask.SourceControl.GithubRepositoryAttributes do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :external_repository_id, :integer
    field :raw_attributes, :map
  end

  def changeset(attributes, attrs) do
    attributes
    |> cast(attrs, [:external_repository_id, :raw_attributes])
    |> validate_required([:external_repository_id, :raw_attributes])
  end
end
