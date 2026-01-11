defmodule Tisktask.TaskLogs do
  @moduledoc false
  use Tisktask.PubSub

  defp new_log_file do
    Path.join(["data", "logs", "#{UUID.uuid4(:hex)}.log"])
  end

  def ensure_log_file! do
    tap(new_log_file(), fn path -> File.touch!(path) end)
  end

  def stream_to(loggable) do
    {:ok, log_file} = Path.safe_relative(loggable.log_file)
    file = File.open!(log_file, [:binary, :append, {:delayed_write, 100, 20}])

    fn line ->
      line = %{id: DateTime.utc_now(:microsecond, Calendar.ISO), log: line}
      publish(loggable, line, "log")
      IO.binwrite(file, "#{DateTime.to_iso8601(line.id)} #{line.log}")
    end
  end

  def stream_from!(loggable) do
    {:ok, log_file} = Path.safe_relative(loggable.log_file)

    log_file
    |> File.stream!(mode: [:read])
    |> Stream.map(fn line -> line |> String.trim() |> String.split(" ", parts: 2) end)
    |> Stream.filter(fn
      [_, _] -> true
      [_] -> false
    end)
    |> Stream.map(fn [index, log] -> %{id: index, log: log} end)
  end
end
