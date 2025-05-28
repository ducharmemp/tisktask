defmodule Tisktask.Factories.Triggers.GithubRepositoryAttributesFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def github_repository_attributes_factory do
        %Tisktask.Triggers.GithubRepositoryAttributes{
          github_repository_id: 1,
          raw_attributes: %{
            "default_branch" => "main",
            "description" => "Test repository",
            "private" => false,
            "created_at" => "2023-01-01T00:00:00Z",
            "updated_at" => "2023-01-02T00:00:00Z"
          }
        }
      end
    end
  end
end
