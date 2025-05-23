defmodule Tisktask.Commands.SpawnJob do
  @moduledoc false
  @command "SPAWNJOB"

  def name, do: @command

  def command(run, args) do
    job = Tasks.create_job!(run, %{program_path: "test"})
    {:noreply, :ok}
  end
end
