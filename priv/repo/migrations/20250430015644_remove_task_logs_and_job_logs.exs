defmodule Tisktask.Repo.Migrations.RemoveTaskLogsAndJobLogs do
  use Ecto.Migration

  def change do
    drop table(:task_job_logs)
    drop table(:task_run_logs)

    alter table(:task_runs) do
      add :log_file, :string, null: false
    end

    alter table(:task_jobs) do
      add :log_file, :string, null: false
    end
  end
end
