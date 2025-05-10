defmodule Tisktask.Repo.Migrations.CreateTriggerReferences do
  use Ecto.Migration

  def change do
    alter table(:task_runs) do
      add :github_trigger_id, references(:github_triggers, on_delete: :delete_all)
      remove :event_id
    end
  end
end
