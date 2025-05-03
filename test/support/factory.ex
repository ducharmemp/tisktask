defmodule Tisktask.Factory do
  use ExMachina.Ecto, repo: Tisktask.Repo
  use Tisktask.Factories.SourceControlEventFactory
  use Tisktask.Factories.Tasks.RunFactory
  use Tisktask.Factories.Tasks.JobFactory
end
