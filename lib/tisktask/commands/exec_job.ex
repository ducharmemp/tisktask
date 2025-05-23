defmodule Tisktask.Commands.ExecJob do
  @moduledoc false
  @command "EXECJOB"

  def name, do: @command

  def command(args) do
    {:reply, :ok}
  end
end
