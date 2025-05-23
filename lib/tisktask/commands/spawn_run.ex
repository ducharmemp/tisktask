defmodule Tisktask.Commands.SpawnRun do
  @moduledoc false
  @command "SPAWNRUN"

  def name, do: @command

  def command(args) do
    {:noreply, :ok}
  end
end
