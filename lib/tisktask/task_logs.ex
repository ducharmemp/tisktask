defmodule Tisktask.TaskLogs do
  @moduledoc false
  use Tisktask.PubSub

  defp logs_dir do
    :tisktask
    |> Application.get_env(:state_dir, "data")
    |> Path.join("logs")
  end

  defp ensure_logs_dir! do
    dir = logs_dir()
    File.mkdir_p!(dir)
    dir
  end

  defp new_log_file do
    Path.join(ensure_logs_dir!(), "#{UUID.uuid4(:hex)}.log")
  end

  def ensure_log_file! do
    path = new_log_file()
    File.touch!(path)
    path
  end

  def stream_to(loggable) do
    file = File.open!(loggable.log_file, [:binary, :append, {:delayed_write, 100, 20}])

    fn line ->
      line = %{id: DateTime.utc_now(:microsecond, Calendar.ISO), log: line}
      publish(loggable, line, "log")
      IO.binwrite(file, "#{DateTime.to_iso8601(line.id)} #{line.log}")
    end
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
