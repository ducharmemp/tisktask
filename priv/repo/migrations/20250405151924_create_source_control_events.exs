defmodule Tisktask.Repo.Migrations.CreateSourceControlEvents do
  use Ecto.Migration

  def change do
    create table(:source_control_events) do
      add :type, :string
      add :payload, :map
      add :originator, :string

      timestamps(type: :utc_datetime)
    end
  end
end
