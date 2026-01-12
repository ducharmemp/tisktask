defmodule Tisktask.Repo.Migrations.ConvertRepositoryAttributesToEmbedded do
  use Ecto.Migration

  def change do
    alter table(:source_control_repositories) do
      add :external_repository_id, :bigint
      add :raw_attributes, :map
    end

    drop table(:github_repository_attributes)
  end
end
