defmodule Tisktask.Commands.SocketListenerTest do
  use ExUnit.Case, async: true

  alias Tisktask.Commands.CommandFixture
  alias Tisktask.Commands.SocketListener

  setup do
    commands = %{
      CommandFixture.name() => CommandFixture
    }

    Phoenix.PubSub.subscribe(Tisktask.PubSub, "tisktask:command")
    {:ok, pid, socket_path} = SocketListener.start_link(commands)
    {:ok, socket} = :gen_tcp.connect({:local, socket_path}, 0, [:binary, active: false])

    on_exit(fn ->
      :gen_tcp.close(socket)
      File.rm(socket_path)
    end)

    {:ok, %{socket: socket}}
  end

  test "handles command successfully", %{socket: socket} do
    # Create a Redis protocol formatted command
    command = "*2\r\n$4\r\nTEST\r\n$3\r\nfoo\r\n"
    :ok = :gen_tcp.send(socket, command)

    {:ok, data} = :gen_tcp.recv(socket, 0)

    assert_receive ["foo"]
    assert data == "*1\r\n$2\r\nOK\r\n"
  end

  test "handles unknown command", %{socket: socket} do
    # Send unknown command
    command = "*1\r\n$7\r\nUNKNOWN\r\n"
    :ok = :gen_tcp.send(socket, command)
  end

  test "handles partial data", %{socket: socket} do
    # Send command in parts
    command_part1 = "*2\r\n$4"
    command_part2 = "\r\nTEST\r\n"
    command_part3 = "$3\r\nfoo\r\n"

    :ok = :gen_tcp.send(socket, command_part1)
    :ok = :gen_tcp.send(socket, command_part2)
    :ok = :gen_tcp.send(socket, command_part3)
    {:ok, data} = :gen_tcp.recv(socket, 0)

    assert_receive ["foo"]
    assert data == "*1\r\n$2\r\nOK\r\n"
  end
end
