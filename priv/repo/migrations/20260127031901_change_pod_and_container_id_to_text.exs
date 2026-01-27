defmodule Tisktask.Repo.Migrations.ChangePodAndContainerIdToText do
  use Ecto.Migration

  def change do
    alter table(:task_jobs) do
      modify :pod_id, :text, from: :string
      modify :container_id, :text, from: :string
    end
  end
end
