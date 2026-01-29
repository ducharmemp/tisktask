defmodule Tisktask.Commands do
  @moduledoc false
  alias Tisktask.Commands.SocketListener
  alias Tisktask.Tasks.Job
  alias Tisktask.Tasks.Run

  def spawn_command_listeners(%Run{} = run, %Job{} = job) do
    {:ok, _pid, socket_path} = SocketListener.start_link(run, job)
    socket_path
  end
end
