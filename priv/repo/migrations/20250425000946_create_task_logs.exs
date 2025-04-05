defmodule Tisktask.Repo.Migrations.CreateTaskLogs do
  use Ecto.Migration

  def change do
    create table(:task_run_logs) do
      add(:log, :text)
      add(:kind, :text)
      add(:task_run_id, references(:task_runs, on_delete: :delete_all), null: false)

      timestamps(type: :utc_datetime)
    end

    alter table(:task_runs) do
      remove(:log_file)
    end
  end
end
