defmodule Tisktask.Commands.SocketListener do
  @moduledoc false
  use ThousandIsland.Handler

  alias Tisktask.Commands.ExecJob
  alias Tisktask.Commands.SpawnContainer
  alias Tisktask.Commands.SpawnJob
  alias Tisktask.Tasks
  alias Tisktask.Tasks.Job
  alias Tisktask.Tasks.Run

  @commands %{
    SpawnJob.name() => SpawnJob,
    SpawnContainer.name() => SpawnContainer,
    ExecJob.name() => ExecJob
  }

  @doc false
  def start_link(%Run{} = run, %Job{} = job, commands \\ @commands) do
    socket_dir = 
      :tisktask
      |> Application.get_env(:state_dir, "data")
      |> Path.join("socket")
    File.mkdir_p!(socket_dir)
    socket_name = UUID.uuid4(:hex)
    socket_path = Path.join(socket_dir, socket_name)

    {:ok, pid} =
      ThousandIsland.start_link(
        port: 0,
        transport_options: [ip: {:local, socket_path}],
        handler_module: __MODULE__,
        handler_options: %{continuation: nil, commands: commands, run: run, job: job}
      )

    File.chmod!(socket_path, 0o766)

    {:ok, pid, socket_path}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %{continuation: continuation, commands: commands, run: run, job: job} = state) do
    case decode_command(data, continuation || (&Redix.Protocol.parse/1)) do
      {:ok, command} ->
        :ok =
          command
          |> dispatch_command(commands, run, job)
          |> respond_to_client(socket)

        {:continue, %{state | continuation: nil}}

      {:continue, continuation} ->
        {:continue, %{state | continuation: continuation}}

      {:error, error} ->
        {:error, error}
    end
  end

  def handle_info({"task_jobs:updated:" <> _id, %Job{} = _job}, {socket, state}) do
    {:noreply, {socket, state}}
  end

  def handle_info(msg, {socket, state}) do
    require Logger

    Logger.debug("SocketListener received unexpected message: #{inspect(msg)}")
    {:noreply, {socket, state}}
  end

  defp decode_command(data, decoder) do
    case decoder.(data) do
      {:ok, %Redix.Error{} = error, ""} -> {:error, error}
      {:ok, command, ""} -> {:ok, command}
      {:ok, _command, rest} when byte_size(rest) > 0 -> {:error, :extra_bytes_after_reply}
      {:continuation, continuation} -> {:continue, continuation}
    end
  end

  defp dispatch_command([command | args], commands, run, job) do
    case Map.get(commands, command) do
      nil ->
        {:error, :unknown_command}

      command_module ->
        job = Tasks.get_job!(job.id)

        case command_module.command(run, job, args) do
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

  defp respond_to_client({:noreply, _reply}, _socket) do
    :ok
  end

  defp respond_to_client({:error, error}, socket) do
    ThousandIsland.Socket.send(socket, Redix.Protocol.pack([error]))
    {:error, error}
  end
end
