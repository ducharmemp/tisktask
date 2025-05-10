defmodule Tisktask.Factories.Triggers.GithubFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def github_trigger_factory do
        %Tisktask.Triggers.Github{
          type: "push",
          action: "created",
          payload: %{
            "after" => "1234567890abcdef1234567890abcdef12345678"
          }
        }
      end
    end
  end
end
