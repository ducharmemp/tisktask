defmodule Tisktask.Commands do
  @moduledoc false
  alias Tisktask.Commands.SocketListener

  def spawn_command_listeners do
    {:ok, _, socket_path} = SocketListener.start_link()
    socket_path
  end
end
