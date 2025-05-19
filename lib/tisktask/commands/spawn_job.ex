defmodule Tisktask.Commands.SpawnJob do
  @moduledoc false
  @command "SPAWNJOB"

  def name, do: @command

  def command(args) do
    {:noreply, :ok}
  end
end
