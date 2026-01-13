defmodule Tisktask.Repo.Migrations.CreateForgejoTriggers do
  use Ecto.Migration

  def change do
    create table(:forgejo_triggers) do
      add :type, :string, null: false
      add :action, :string
      add :payload, :map, null: false

      add :source_control_repository_id,
          references(:source_control_repositories, on_delete: :delete_all),
          null: false

      timestamps()
    end
  end
end
