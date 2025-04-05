defmodule Tisktask.Repo.Migrations.AddExitStatusToRunStatus do
  use Ecto.Migration

  def change do
    alter table(:task_runs) do
      add :exit_status, :integer
    end
  end
end
