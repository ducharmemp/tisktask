defmodule Tisktask.Repo.Migrations.MakeLogFilesUnique do
  use Ecto.Migration

  def change do
    create index(:task_runs, [:log_file], unique: true)
    create index(:task_jobs, [:log_file], unique: true)
  end
end
