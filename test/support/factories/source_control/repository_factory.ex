defmodule Tisktask.Factories.SourceControl.RepositoryFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def source_control_repository_factory do
        %Tisktask.SourceControl.Repository{
          name: "test-repo",
          url: "https://github.com/test-org/test-repo.git",
          api_token: "test-token",
          external_repository_id: sequence(:external_repository_id, & &1),
          raw_attributes: %{
            "default_branch" => "main",
            "description" => "Test repository",
            "private" => false,
            "statuses_url" => "https://api.github.com/repos/test-org/test-repo/statuses/{sha}"
          }
        }
      end
    end
  end
end
