defmodule Tisktask.TaskLogs do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Phoenix.PubSub
  alias Tisktask.Tasks.Job
  alias Tisktask.Tasks.Run

  use Agent
  use Bitwise

  def start_link(_initial_state) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  defp new_log_file() do
    # 48 bits
    now = System.os_time(:millisecond)

    node_name_hash =
      Node.self()
      |> Atom.to_charlist()
      |> Enum.reduce(0, fn char, hash ->
        (hash <<< 5) - hash + char &&& 0xFFFF
      end)

    # 32 bits
    # 16 bits
    n = Agent.get_and_update(__MODULE__, fn n -> {n, n + 1 &&& 0xFF} end)
    log_id = <<now::48, node_name_hash::16, n::8>> |> Base.url_encode64(padding: false)
    Path.join(["data", "logs", "#{log_id}.log"])
  end

  def subscribe_to(%Run{} = run) do
    PubSub.subscribe(Tisktask.PubSub, "run_log:#{run.id}")
  end

  def subscribe_to(%Job{} = job) do
    PubSub.subscribe(Tisktask.PubSub, "job_log:#{job.id}")
  end

  def ensure_log_file!() do
    new_log_file() |> tap(fn path -> File.touch!(path) end)
  end

  def stream_to(loggable) do
    Tisktask.Tasks.LogFile.new(loggable)
  end

  def stream_from!(loggable) do
    File.stream!(loggable.log_file, mode: [:read])
    |> Stream.with_index()
    |> Stream.map(fn {log, index} -> %{id: index, log: log} end)
  end
end
