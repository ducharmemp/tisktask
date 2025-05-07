defmodule Tisktask.Factories.Tasks.RunFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def task_run_factory do
        %Tisktask.Tasks.Run{
          status: :staged,
          github_trigger: build(:github_trigger),
          log_file: "some log file",
          jobs: []
        }
      end
    end
  end
end
