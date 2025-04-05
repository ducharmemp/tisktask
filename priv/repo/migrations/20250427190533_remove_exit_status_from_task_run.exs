defmodule Tisktask.Repo.Migrations.RemoveExitStatusFromTaskRun do
  use Ecto.Migration

  def change do
    alter table(:task_runs) do
      remove :exit_status
    end
  end
end
