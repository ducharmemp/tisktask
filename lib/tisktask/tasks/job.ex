defmodule Tisktask.Tasks.Job do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "task_jobs" do
    field :program_path, :string
    field :exit_status, :integer
    field :log_file, :string
    field :pod_id, :string
    field :container_id, :string
    field :command_socket_path, :string
    belongs_to(:parent_run, Tisktask.Tasks.Run, foreign_key: :task_run_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task_job, attrs) do
    task_job
    |> cast(attrs, [:program_path, :exit_status, :log_file, :pod_id, :container_id, :command_socket_path])
    |> validate_required([:program_path, :log_file])
    |> unique_constraint(:log_file)
  end

  def associate_with_parent(task_job, parent_run) do
    put_assoc(task_job, :parent_run, parent_run)
  end
end
