defmodule Tisktask.Triggers.GithubRepositoryAttributes do
  @moduledoc false
  use Ecto.Schema

  schema "github_repository_attributes" do
    field :github_repository_id, :integer

    timestamps(type: :utc_datetime)
  end
end
