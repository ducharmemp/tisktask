defmodule Tisktask.Repo.Migrations.CreateGithubTrigger do
  use Ecto.Migration

  def change do
    create(table(:github_triggers)) do
      add :type, :string, null: false
      add :action, :string
      add :payload, :map, null: false
      add :github_repository_id, :bigint
      timestamps()
    end
  end
end
