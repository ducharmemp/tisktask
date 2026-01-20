defmodule Tisktask.Repo.Migrations.AddPodAndContainerIdToTaskJobs do
  use Ecto.Migration

  def change do
    alter table(:task_jobs) do
      add :pod_id, :string
      add :container_id, :string
    end
  end
end
