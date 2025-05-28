defmodule Tisktask.Factories.Triggers.GithubRepositoryFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def github_repository_factory do
        %Tisktask.Triggers.GithubRepository{
          name: "test-repo",
          url: "httpsL//github.com/test-org/test-repo.git",
          api_token: "test-token",
          github_repository_attributes: build(:github_repository_attributes)
        }
      end
    end
  end
end
