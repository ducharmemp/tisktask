defmodule Tisktask.TaskLogs do
  @moduledoc false
  use Agent

  import Bitwise
  import Ecto.Query, warn: false

  alias Phoenix.PubSub
  alias Tisktask.Tasks.Job
  alias Tisktask.Tasks.Run

  def start_link(_initial_state) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  defp new_log_file do
    Path.join(["data", "logs", "#{UUID.uuid4(:hex)}.log"])
  end

  def subscribe_to(%Run{} = run) do
    PubSub.subscribe(Tisktask.PubSub, "run_log:#{run.id}")
  end

  def subscribe_to(%Job{} = job) do
    PubSub.subscribe(Tisktask.PubSub, "job_log:#{job.id}")
  end

  def ensure_log_file! do
    tap(new_log_file(), fn path -> File.touch!(path) end)
  end

  def stream_to(loggable) do
    Tisktask.Tasks.LogFile.new(loggable)
  end

  def stream_from!(loggable) do
    loggable.log_file
    |> File.stream!(mode: [:read])
    |> Stream.map(fn line -> line |> String.trim() |> String.split(" ", parts: 2) end)
    |> Stream.filter(fn
      [_, _] -> true
      [_] -> false
    end)
    |> Stream.map(fn [index, log] -> %{id: index, log: log} end)
  end
end
