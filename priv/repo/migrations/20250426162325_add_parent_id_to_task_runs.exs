defmodule Tisktask.Repo.Migrations.AddParentIdToTaskRuns do
  use Ecto.Migration

  def change do
    alter table(:task_runs) do
      add :parent_id, references(:task_runs, on_delete: :nothing)
    end
  end
end
