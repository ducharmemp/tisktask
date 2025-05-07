defmodule Tisktask.Factories.Tasks.RunFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def task_run_factory do
        %Tisktask.Tasks.Run{
          status: :staged,
          github_trigger: build(:github_trigger),
          log_file: "some log file"
        }
      end

      def with_jobs(%Tisktask.Tasks.Run{} = run, count) do
        insert_list(:task_job, count, task_run_id: run.id)
      end
    end
  end
end
