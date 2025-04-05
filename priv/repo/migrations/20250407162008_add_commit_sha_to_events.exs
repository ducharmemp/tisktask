defmodule Tisktask.Repo.Migrations.AddCommitShaToEvents do
  use Ecto.Migration

  def change do
    alter table(:source_control_events) do
      add(:head_sha, :string)
      add(:head_ref, :string)
    end

    create(index(:source_control_events, [:head_sha]))
    create(index(:source_control_events, [:head_ref]))
  end
end
