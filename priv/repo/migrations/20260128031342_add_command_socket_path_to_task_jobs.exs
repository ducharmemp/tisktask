defmodule Tisktask.Repo.Migrations.AddCommandSocketPathToTaskJobs do
  use Ecto.Migration

  def change do
    alter table(:task_jobs) do
      add :command_socket_path, :text
    end
  end
end
