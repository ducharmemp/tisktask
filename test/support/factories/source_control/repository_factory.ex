defmodule Tisktask.Factories.SourceControl.RepositoryFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def source_control_repository_factory do
        %Tisktask.SourceControl.Repository{
          name: "some name",
          url: "some url",
          api_token: "some api token",
          external_repository_id: sequence(:external_repository_id, & &1),
          raw_attributes: %{}
        }
      end
    end
  end
end
