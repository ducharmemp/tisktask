defmodule Tisktask.Commands.SocketListener do
  @moduledoc false
  use ThousandIsland.Handler

  alias Tisktask.Commands.ExecJob
  alias Tisktask.Commands.SpawnJob
  alias Tisktask.Commands.SpawnRun

  @initial_state %{socket: nil, socket_name: nil}
  @socket_path "data/socket"
  @commands %{
    SpawnJob.name() => SpawnJob,
    ExecJob.name() => ExecJob,
    SpawnRun.name() => SpawnRun
  }

  @doc false
  def start_link(commands \\ @commands) do
    socket_name = UUID.uuid4(:hex)
    socket_path = Path.join(@socket_path, socket_name)
    socket_path = Path.expand(socket_path, File.cwd!())

    {:ok, pid} =
      ThousandIsland.start_link(
        port: 0,
        transport_options: [ip: {:local, socket_path}],
        handler_module: __MODULE__,
        handler_options: %{continuation: nil, commands: commands}
      )

    {:ok, pid, socket_path}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %{continuation: continuation, commands: commands} = state) do
    case decode_command(data, continuation || (&Redix.Protocol.parse/1)) do
      {:ok, command} ->
        :ok =
          command
          |> dispatch_command(commands)
          |> respond_to_client(socket)

        {:continue, %{state | continuation: nil}}

      {:continue, continuation} ->
        {:continue, %{state | continuation: continuation}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp decode_command(data, decoder) do
    case decoder.(data) do
      {:ok, %Redix.Error{} = error, ""} -> {:error, error}
      {:ok, command, ""} -> {:ok, command}
      {:ok, _command, rest} when byte_size(rest) > 0 -> {:error, :extra_bytes_after_reply}
      {:continuation, continuation} -> {:continue, continuation}
    end
  end

  defp dispatch_command([command | args], commands) do
    case Map.get(commands, command) do
      nil ->
        {:error, :unknown_command}

      command_module ->
        case command_module.command(args) do
          {:reply, reply} -> {:reply, reply}
          {:noreply, reply} -> {:noreply, reply}
          _ -> {:error, :invalid_command_response}
        end
    end
  end

  defp respond_to_client({:reply, :ok}, socket) do
    ThousandIsland.Socket.send(socket, Redix.Protocol.pack(["OK"]))
  end

  defp respond_to_client({:reply, reply}, socket) do
    ThousandIsland.Socket.send(socket, Redix.Protocol.pack([reply]))
  end

  defp respond_to_client({:noreply, reply}, socket) do
    :ok
  end

  defp respond_to_client({:error, error}, socket) do
    ThousandIsland.Socket.send(socket, Redix.Protocol.pack([error]))
    {:error, error}
  end
end
