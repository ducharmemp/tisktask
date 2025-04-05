defmodule Tisktask.Repo.Migrations.AddRepoUrlToEvents do
  use Ecto.Migration

  def change do
    alter table(:source_control_events) do
      add(:repo_url, :string)
    end

    create(index(:source_control_events, [:repo_url]))
  end
end
