defmodule Tisktask.Commands do
  @moduledoc false
  alias Tisktask.Commands.SocketListener
  alias Tisktask.Tasks.Run

  def spawn_command_listeners(%Run{} = run) do
    {:ok, _pid, socket_path} = SocketListener.start_link(run)
    socket_path
  end
end
