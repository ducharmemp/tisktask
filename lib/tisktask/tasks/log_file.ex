defmodule Tisktask.Tasks.LogFile do
  defstruct [:loggable, :file_stream]

  def new(loggable) do
    %__MODULE__{
      loggable: loggable,
      file_stream: File.stream!(loggable.log_file, mode: [:append])
    }
  end
end

defimpl Collectable, for: Tisktask.Tasks.LogFile do
  alias Phoenix.PubSub
  alias Tisktask.Tasks.Run
  alias Tisktask.Tasks.Job

  def into(%{file_stream: file_stream, loggable: loggable} = log_file) do
    {initial, into} = Collectable.into(file_stream)

    collector_fn = fn
      :ok, {:cont, log} ->
        log = to_identifiable_log(log)
        publish(loggable, log)
        log = to_serializable_log(log)
        into.(:ok, {:cont, log})
        :ok

      :ok, msg ->
        into.(:ok, msg)
    end

    {initial, collector_fn}
  end

  defp to_identifiable_log(line) do
    %{id: DateTime.utc_now(:microsecond, Calendar.ISO), log: line}
  end

  def to_serializable_log(log) do
    id = log.id |> DateTime.to_iso8601()
    "#{id} #{log.log}"
  end

  defp publish(%Run{} = loggable, log) do
    PubSub.broadcast(Tisktask.PubSub, "run_log:#{loggable.id}", {:log, loggable, log})
  end

  defp publish(%Job{} = loggable, log) do
    PubSub.broadcast(Tisktask.PubSub, "job_log:#{loggable.id}", {:log, loggable, log})
  end
end
