defmodule Tisktask.Repo.Migrations.AddEventIdToTaskRun do
  use Ecto.Migration

  def change do
    alter table(:task_runs) do
      add(:event_id, references(:source_control_events, on_delete: :nothing), null: false)
    end

    create(index(:task_runs, [:event_id]))
  end
end
