defmodule Tisktask.Repo.Migrations.UnifyTriggersTable do
  use Ecto.Migration

  def change do
    # Create the unified triggers table
    create table(:triggers) do
      add :provider, :string, null: false
      add :type, :string, null: false
      add :action, :string
      add :payload, :map, null: false

      add :source_control_repository_id,
          references(:source_control_repositories, on_delete: :delete_all),
          null: false

      timestamps()
    end

    create index(:triggers, [:provider])
    create index(:triggers, [:source_control_repository_id])

    # Update task_runs to reference the new triggers table
    alter table(:task_runs) do
      remove :github_trigger_id
      add :trigger_id, references(:triggers, on_delete: :delete_all)
    end

    # Drop the old tables
    drop table(:github_triggers)
    drop table(:forgejo_triggers)
  end
end
