defmodule Tisktask.Repo.Migrations.CreateTaskRunLogs do
  use Ecto.Migration

  def change do
    alter table(:task_runs) do
      add(:log_file, :text)
    end
  end
end
