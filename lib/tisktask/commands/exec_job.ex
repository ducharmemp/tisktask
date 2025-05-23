defmodule Tisktask.Commands.ExecJob do
  @moduledoc false
  @command "EXECJOB"

  def name, do: @command

  def command(run, args) do
    job = Tasks.create_job!(run, %{program_path: "test"})
    Tasks.subscribe_to(job, "updated")
    {:noreply, %{job_id: job.id}}
  end
end
