defmodule Tisktask.Factories.Triggers.GithubRepositoryFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def github_repository_factory do
        %Tisktask.Triggers.GithubRepository{
          name: "test-repo",
          url: "https://github.com/test-org/test-repo.git",
          api_token: "test-token"
        }
      end
    end
  end
end
