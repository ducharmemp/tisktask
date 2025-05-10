defmodule Tisktask.Factories.SourceControl.GithubRepositoryAttributesFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def source_control_github_repository_attributes_factory do
        %Tisktask.SourceControl.GithubRepositoryAttributes{
          github_repository_id: 123_456_789,
          raw_attributes: %{
            "id" => 123_456_789,
            "name" => "some name",
            "clone_url" => "some clone url",
            "owner" => %{
              "login" => "some owner login",
              "id" => 987_654_321
            }
          }
        }
      end
    end
  end
end
