defmodule Tisktask.SourceControlTest do
  use Tisktask.DataCase, async: true

  alias Tisktask.SourceControl

  describe "source_control_repositories" do
    alias Tisktask.SourceControl.Repository

    @invalid_attrs %{name: nil, url: nil}

    test "list_source_control_repositories/0 returns all source_control_repositories" do
      repositories = insert(:source_control_repository)
      assert SourceControl.list_repositories() == [repositories]
    end

    test "get_repository!/1 returns the repositories with given id" do
      repositories = insert(:source_control_repository)
      assert SourceControl.get_repository!(repositories.id) == repositories
    end

    test "create_repository/1 with valid data creates a repositories" do
      valid_attrs = %{name: "some name", url: "some url", api_token: "some token"}

      assert {:ok, %Repository{} = repository} =
               SourceControl.create_repository(valid_attrs)

      assert repository.name == "some name"
      assert repository.url == "some url"
    end

    test "create_repository/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SourceControl.create_repository(@invalid_attrs)
    end

    test "update_repository/2 with valid data updates the repositories" do
      repositories = insert(:source_control_repository)
      update_attrs = %{name: "some updated name", url: "some updated url"}

      assert {:ok, %Repository{} = repositories} =
               SourceControl.update_repository(repositories, update_attrs)

      assert repositories.name == "some updated name"
      assert repositories.url == "some updated url"
    end

    test "update_repository/2 with invalid data returns error changeset" do
      repositories = insert(:source_control_repository)

      assert {:error, %Ecto.Changeset{}} =
               SourceControl.update_repository(repositories, @invalid_attrs)

      assert repositories == SourceControl.get_repository!(repositories.id)
    end

    test "delete_repository/1 deletes the repositories" do
      repositories = insert(:source_control_repository)
      assert {:ok, %Repository{}} = SourceControl.delete_repository(repositories)
      assert_raise Ecto.NoResultsError, fn -> SourceControl.get_repository!(repositories.id) end
    end

    test "change_repository/1 returns a repositories changeset" do
      repositories = insert(:source_control_repository)
      assert %Ecto.Changeset{} = SourceControl.change_repository(repositories)
    end
  end

  describe "synchronize_from_github!/2" do
    test "it creates a repository with matching github attributes" do
      Req.Test.stub(SourceControl, fn conn ->
        Req.Test.json(conn, %{
          "id" => 123,
          "name" => "some name",
          "clone_url" => "some url",
          "owner" => %{"login" => "some owner"}
        })
      end)

      {:ok, repository} =
        SourceControl.synchronize_from_github!("some_owner/some_repo", "some_token")

      assert %SourceControl.Repository{} = repository
    end
  end
end
