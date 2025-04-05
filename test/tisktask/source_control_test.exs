defmodule Tisktask.SourceControlTest do
  use Tisktask.DataCase

  alias Tisktask.SourceControl

  describe "source_control_events" do
    alias Tisktask.SourceControl.Event

    @invalid_attrs %{type: nil, payload: nil, originator: nil}

    test "list_source_control_events/0 returns all source_control_events" do
      event = event_fixture()
      assert SourceControl.list_source_control_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert SourceControl.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{type: "some type", payload: %{}, originator: "some originator"}

      assert {:ok, %Event{} = event} = SourceControl.create_event(valid_attrs)
      assert event.type == "some type"
      assert event.payload == %{}
      assert event.originator == "some originator"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SourceControl.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()

      update_attrs = %{
        type: "some updated type",
        payload: %{},
        originator: "some updated originator"
      }

      assert {:ok, %Event{} = event} = SourceControl.update_event(event, update_attrs)
      assert event.type == "some updated type"
      assert event.payload == %{}
      assert event.originator == "some updated originator"
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = SourceControl.update_event(event, @invalid_attrs)
      assert event == SourceControl.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = SourceControl.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> SourceControl.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = SourceControl.change_event(event)
    end
  end

  describe "source_control_repositories" do
    import Tisktask.SourceControlFixtures

    alias Tisktask.SourceControl.Repository

    @invalid_attrs %{name: nil, url: nil}

    test "list_source_control_repositories/0 returns all source_control_repositories" do
      repositories = repositories_fixture()
      assert SourceControl.list_source_control_repositories() == [repositories]
    end

    test "get_repositories!/1 returns the repositories with given id" do
      repositories = repositories_fixture()
      assert SourceControl.get_repositories!(repositories.id) == repositories
    end

    test "create_repositories/1 with valid data creates a repositories" do
      valid_attrs = %{name: "some name", url: "some url"}

      assert {:ok, %Repository{} = repositories} =
               SourceControl.create_repositories(valid_attrs)

      assert repositories.name == "some name"
      assert repositories.url == "some url"
    end

    test "create_repositories/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SourceControl.create_repositories(@invalid_attrs)
    end

    test "update_repositories/2 with valid data updates the repositories" do
      repositories = repositories_fixture()
      update_attrs = %{name: "some updated name", url: "some updated url"}

      assert {:ok, %Repository{} = repositories} =
               SourceControl.update_repositories(repositories, update_attrs)

      assert repositories.name == "some updated name"
      assert repositories.url == "some updated url"
    end

    test "update_repositories/2 with invalid data returns error changeset" do
      repositories = repositories_fixture()

      assert {:error, %Ecto.Changeset{}} =
               SourceControl.update_repositories(repositories, @invalid_attrs)

      assert repositories == SourceControl.get_repositories!(repositories.id)
    end

    test "delete_repositories/1 deletes the repositories" do
      repositories = repositories_fixture()
      assert {:ok, %Repository{}} = SourceControl.delete_repositories(repositories)
      assert_raise Ecto.NoResultsError, fn -> SourceControl.get_repositories!(repositories.id) end
    end

    test "change_repositories/1 returns a repositories changeset" do
      repositories = repositories_fixture()
      assert %Ecto.Changeset{} = SourceControl.change_repositories(repositories)
    end
  end
end
