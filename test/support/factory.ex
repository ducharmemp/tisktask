defmodule Tisktask.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Tisktask.Repo
  use Tisktask.Factories.SourceControlEventFactory
  use Tisktask.Factories.Tasks.RunFactory
  use Tisktask.Factories.Tasks.JobFactory
end
