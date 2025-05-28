defmodule Tisktask.Repo.Migrations.ChangeTriggerToSourceControlForeignKey do
  use Ecto.Migration

  def change do
    alter table(:github_triggers) do
      remove :github_repository_id

      add :source_control_repository_id,
          references(:source_control_repositories, on_delete: :delete_all),
          null: false
    end
  end
end
