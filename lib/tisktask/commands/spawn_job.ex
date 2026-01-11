defmodule Tisktask.Commands.SpawnJob do
  @moduledoc false
  alias Tisktask.Tasks

  @command "SPAWNJOB"

  def name, do: @command

  def command(run, _args) do
    _job = Tasks.create_job!(run, %{program_path: "test"})
    {:noreply, :ok}
  end
end
