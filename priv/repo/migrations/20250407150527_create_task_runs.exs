defmodule Tisktask.Repo.Migrations.CreateTaskRuns do
  use Ecto.Migration

  def change do
    create table(:task_runs) do
      add :status, :text

      timestamps(type: :utc_datetime)
    end
  end
end
