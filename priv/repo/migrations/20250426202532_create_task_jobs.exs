defmodule Tisktask.Repo.Migrations.CreateTaskJobs do
  use Ecto.Migration

  def change do
    create table(:task_jobs) do
      add :program_path, :string
      add :exit_status, :integer
      add :task_run_id, references(:task_runs, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    alter table(:task_runs) do
      remove :parent_id
      add :parent_job_id, references(:task_jobs, on_delete: :nothing)
    end

    create table(:task_job_logs) do
      add(:log, :text)
      add(:kind, :text)
      add(:task_job_id, references(:task_jobs, on_delete: :delete_all), null: false)

      timestamps(type: :utc_datetime)
    end
  end
end
