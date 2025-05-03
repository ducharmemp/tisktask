defmodule Tisktask.Factories.SourceControlEventFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def source_control_event_factory do
        %Tisktask.SourceControl.Event{
          originator: "some originator",
          payload: %{},
          type: "some type",
          head_sha: "some sha",
          head_ref: "some ref",
          repo: build(:source_control_repository)
        }
      end

      def source_control_repository_factory do
        %Tisktask.SourceControl.Repository{
          name: "some name",
          url: "some url",
          api_token: "some token"
        }
      end
    end
  end
end
