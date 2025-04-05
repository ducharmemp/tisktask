defmodule TisktaskWeb.EventControllerTest do
  use TisktaskWeb.ConnCase

  import Tisktask.SourceControlFixtures

  alias Tisktask.SourceControl.Event

  @create_attrs %{
    type: "some type",
    payload: %{},
    originator: "some originator"
  }
  @update_attrs %{
    type: "some updated type",
    payload: %{},
    originator: "some updated originator"
  }
  @invalid_attrs %{type: nil, payload: nil, originator: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all source_control_events", %{conn: conn} do
      conn = get(conn, ~p"/api/source_control_events")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create event" do
    test "renders event when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/source_control_events", event: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/source_control_events/#{id}")

      assert %{
               "id" => ^id,
               "originator" => "some originator",
               "payload" => %{},
               "type" => "some type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/source_control_events", event: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update event" do
    setup [:create_event]

    test "renders event when data is valid", %{conn: conn, event: %Event{id: id} = event} do
      conn = put(conn, ~p"/api/source_control_events/#{event}", event: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/source_control_events/#{id}")

      assert %{
               "id" => ^id,
               "originator" => "some updated originator",
               "payload" => %{},
               "type" => "some updated type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, event: event} do
      conn = put(conn, ~p"/api/source_control_events/#{event}", event: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete event" do
    setup [:create_event]

    test "deletes chosen event", %{conn: conn, event: event} do
      conn = delete(conn, ~p"/api/source_control_events/#{event}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/source_control_events/#{event}")
      end
    end
  end

  defp create_event(_) do
    event = event_fixture()

    %{event: event}
  end
end
