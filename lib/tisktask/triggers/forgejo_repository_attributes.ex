defmodule Tisktask.Triggers.ForgejoRepositoryAttributes do
  @moduledoc false
  use Ecto.Schema

  schema "source_control_repository_attributes" do
    field :github_repository_id, :integer
    field :raw_attributes, :map

    belongs_to :github_repository, Tisktask.Triggers.ForgejoRepository, foreign_key: :source_control_repository_id

    timestamps(type: :utc_datetime)
  end
end
