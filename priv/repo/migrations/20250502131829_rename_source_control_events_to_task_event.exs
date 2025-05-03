defmodule Tisktask.Repo.Migrations.RenameSourceControlEventsToTaskEvent do
  use Ecto.Migration

  def change do
    rename table(:source_control_events), to: table(:task_events)

    alter table(:task_runs) do
      remove(:parent_job_id)
    end
  end
end
