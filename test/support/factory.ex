defmodule Tisktask.Factory do
  use ExMachina.Ecto, repo: Tisktask.Repo

  import Tisktask.Factories.SourceControlEventFactory
end
