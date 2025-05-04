defmodule Tisktask.Triggers do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Tisktask.Repo
  alias Tisktask.Triggers.Github

  def create_github_trigger(attrs \\ %{}) do
    %Github{}
    |> Github.changeset(attrs)
    |> Repo.insert()
  end

  def repository_for(trigger) do
  end
end
