defmodule Tisktask.Factories.Tasks.RunFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def task_run_factory do
        %Tisktask.Tasks.Run{
          status: :staged,
          event: build(:source_control_event),
          log_file: "some log file",
          jobs: []
        }
      end
    end
  end
end
