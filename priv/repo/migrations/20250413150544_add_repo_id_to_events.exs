defmodule Tisktask.Repo.Migrations.AddRepoIdToEvents do
  use Ecto.Migration

  def change do
    alter table(:source_control_events) do
      add(:repo_id, references(:source_control_repositories, on_delete: :delete_all), null: false)
      remove(:repo_url)
    end

    create(index(:source_control_events, [:repo_id]))
  end
end
