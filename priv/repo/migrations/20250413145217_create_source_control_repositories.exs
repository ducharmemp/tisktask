defmodule Tisktask.Repo.Migrations.CreateSourceControlrepository do
  use Ecto.Migration

  def change do
    create table(:source_control_repositories) do
      add :name, :text
      add :url, :text
      add :api_token, :text

      timestamps(type: :utc_datetime)
    end
  end
end
