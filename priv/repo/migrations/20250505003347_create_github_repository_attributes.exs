defmodule Tisktask.Repo.Migrations.CreateGithubRepositoryAttributes do
  use Ecto.Migration

  def change do
    create table(:github_repository_attributes) do
      add :source_control_repository_id,
          references(:source_control_repositories, on_delete: :delete_all),
          null: false

      add :github_repository_id, :bigint, null: false
      add :raw_attributes, :map, null: false
      timestamps()
    end
  end
end
