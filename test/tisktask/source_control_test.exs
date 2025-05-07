defmodule Tisktask.SourceControlTest do
  use Tisktask.DataCase

  alias Tisktask.SourceControl

  describe "source_control_repositories" do
    alias Tisktask.SourceControl.Repository

    @invalid_attrs %{name: nil, url: nil}

    test "list_source_control_repositories/0 returns all source_control_repositories" do
      repositories = insert(:source_control_repository)
      assert SourceControl.list_source_control_repositories() == [repositories]
    end

    test "get_repositories!/1 returns the repositories with given id" do
      repositories = insert(:source_control_repository)
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
      repositories = insert(:source_control_repository)
      update_attrs = %{name: "some updated name", url: "some updated url"}

      assert {:ok, %Repository{} = repositories} =
               SourceControl.update_repositories(repositories, update_attrs)

      assert repositories.name == "some updated name"
      assert repositories.url == "some updated url"
    end

    test "update_repositories/2 with invalid data returns error changeset" do
      repositories = insert(:source_control_repository)

      assert {:error, %Ecto.Changeset{}} =
               SourceControl.update_repositories(repositories, @invalid_attrs)

      assert repositories == SourceControl.get_repositories!(repositories.id)
    end

    test "delete_repositories/1 deletes the repositories" do
      repositories = insert(:source_control_repository)
      assert {:ok, %Repository{}} = SourceControl.delete_repositories(repositories)
      assert_raise Ecto.NoResultsError, fn -> SourceControl.get_repositories!(repositories.id) end
    end

    test "change_repositories/1 returns a repositories changeset" do
      repositories = insert(:source_control_repository)
      assert %Ecto.Changeset{} = SourceControl.change_repositories(repositories)
    end
  end
end
