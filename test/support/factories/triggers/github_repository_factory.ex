defmodule Tisktask.Factories.Triggers.GithubRepositoryFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def github_repository_factory do
        %Tisktask.Triggers.GithubRepository{
          name: "test-repo",
          url: "https://github.com/test-org/test-repo.git",
          api_token: "test-token",
          external_repository_id: sequence(:external_repository_id, & &1),
          raw_attributes: %{
            "default_branch" => "main",
            "description" => "Test repository",
            "private" => false,
            "created_at" => "2023-01-01T00:00:00Z",
            "updated_at" => "2023-01-02T00:00:00Z",
            "statuses_url" => "https://api.github.com/repos/test-org/test-repo/statuses/{sha}"
          }
        }
      end
    end
  end
end
