defmodule Tisktask.Tasks.Run do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Tisktask.Triggers

  schema "task_runs" do
    field(:status, Ecto.Enum, values: [:staged, :running, :completed, :timeout])
    field(:log_file, :string)
    field(:any_jobs_failed?, :boolean, default: false, virtual: true)
    has_many(:jobs, Tisktask.Tasks.Job, foreign_key: :task_run_id)

    belongs_to(:github_trigger, Tisktask.Triggers.Github)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(run, attrs) do
    run
    |> cast(attrs, [:status, :log_file])
    |> validate_required([:status, :log_file])
    |> unique_constraint(:log_file)
  end

  def trigger_from(run, %Triggers.Github{} = trigger) do
    put_assoc(run, :github_trigger, trigger)
  end
end
