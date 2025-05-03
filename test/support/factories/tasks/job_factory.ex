defmodule Tisktask.Factories.Tasks.JobFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def task_job_factory do
        %Tisktask.Tasks.Job{
          program_path: "some program path",
          exit_status: 0,
          log_file: "some log file",
          parent_run: build(:task_run)
        }
      end
    end
  end
end
