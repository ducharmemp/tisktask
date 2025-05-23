defmodule Tisktask.Commands.CommandFixture do
  @moduledoc false
  def name, do: "TEST"

  def command(args) do
    Phoenix.PubSub.broadcast(Tisktask.PubSub, "tisktask:command", args)
    {:reply, :ok}
  end
end
