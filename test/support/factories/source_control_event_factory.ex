defmodule Tisktask.Factories.SourceControlEventFactory do
  use ExMachina

  def source_control_event_factory do
    %Tisktask.SourceControl.Event{
      originator: "some originator",
      payload: %{},
      type: "some type",
      head_sha: "some sha",
      head_ref: "some ref",
      repo: build(:repository),
    }
  end
end
