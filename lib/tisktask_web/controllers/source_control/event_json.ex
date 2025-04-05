defmodule TisktaskWeb.SourceControl.EventJSON do
  alias Tisktask.SourceControl.Event

  @doc """
  Renders a list of source_control_events.
  """
  def index(%{source_control_events: source_control_events}) do
    %{data: for(event <- source_control_events, do: data(event))}
  end

  @doc """
  Renders a single event.
  """
  def show(%{event: event}) do
    %{data: data(event)}
  end

  defp data(%Event{} = event) do
    %{
      id: event.id,
      type: event.type,
      payload: event.payload,
      originator: event.originator
    }
  end
end
