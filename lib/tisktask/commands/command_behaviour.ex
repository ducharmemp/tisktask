defmodule Tisktask.Commands.CommandBehaviour do
  @moduledoc false
  @callback name() :: String.t()
  @callback command(list()) :: {:reply, any()} | {:noreply, any()}
end
