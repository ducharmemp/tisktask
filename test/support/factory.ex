defmodule Tisktask.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Tisktask.Repo
  use Tisktask.Factories.Tasks.RunFactory
  use Tisktask.Factories.Tasks.JobFactory
  use Tisktask.Factories.Triggers.GithubFactory
  use Tisktask.Factories.SourceControl.RepositoryFactory
  use Tisktask.Factories.SourceControl.GithubRepositoryAttributesFactory
end
