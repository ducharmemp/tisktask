defmodule Tisktask.Commands.ExecJob do
  @moduledoc false
  alias Tisktask.Tasks

  @command "EXECJOB"

  def name, do: @command

  def command(run, _job, _args) do
    job = Tasks.create_job!(run, %{program_path: "test"})
    Tasks.subscribe_to(job, "updated")
    {:noreply, %{job_id: job.id}}
  end
end
