defmodule Tisktask.SourceControl.EventBuilder do
  @moduledoc false
  alias Tisktask.SourceControl
  alias Tisktask.SourceControl.Event

  def build(originator, headers, body) do
    attrs =
      %{}
      |> extract_from_body(body)
      |> extract_from_headers(headers)
      |> Map.put(:originator, originator)

    repo = SourceControl.get_repository_by_url(get_in(body, ["repository", "clone_url"]))

    %Event{} |> Event.changeset(attrs) |> Event.change_repo(repo) |> Tisktask.Repo.insert()
  end

  def extract_from_body(attrs, payload) do
    Map.merge(%{head_ref: Map.get(payload, "ref"), head_sha: Map.get(payload, "after"), payload: payload}, attrs)
  end

  def extract_from_headers(attrs, headers) do
    Map.merge(%{type: Map.get(headers, "x-forgejo-event")}, attrs)
  end
end
