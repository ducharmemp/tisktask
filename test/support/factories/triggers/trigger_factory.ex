defmodule Tisktask.Factories.Triggers.TriggerFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def trigger_factory do
        %Tisktask.Triggers.Trigger{
          provider: "github",
          type: "push",
          action: "created",
          source_control_repository: build(:source_control_repository),
          payload: %{
            "after" => "1234567890abcdef1234567890abcdef12345678"
          }
        }
      end

      def github_trigger_factory do
        build(:trigger, provider: "github")
      end

      def forgejo_trigger_factory do
        build(:trigger, provider: "forgejo")
      end
    end
  end
end
