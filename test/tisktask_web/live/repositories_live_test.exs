defmodule TisktaskWeb.repositoryLiveTest() do
  use TisktaskWeb.ConnCase

  import Phoenix.LiveViewTest
  import Tisktask.SourceControlFixtures

  @create_attrs %{name: "some name", url: "some url"}
  @update_attrs %{name: "some updated name", url: "some updated url"}
  @invalid_attrs %{name: nil, url: nil}
  defp create_repository(_) do
    repository = repository_fixture()

    %{repository: repository}
  end

  describe "Index" do
    setup [:create_repository]

    test "lists all source_control_repository", %{conn: conn, repository: repository} do
      {:ok, _index_live, html} = live(conn, ~p"/source_control_repository")

      assert html =~ "Listing Source control repository"
      assert html =~ repository.name
    end

    test "saves new repository", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/source_control_repository")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New repository")
               |> render_click()
               |> follow_redirect(conn, ~p"/source_control_repository/new")

      assert render(form_live) =~ "New repository"

      assert form_live
             |> form("#repository-form", repository: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#repository-form", repository: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/source_control_repository")

      html = render(index_live)
      assert html =~ "repository created successfully"
      assert html =~ "some name"
    end

    test "updates repository in listing", %{conn: conn, repository: repository} do
      {:ok, index_live, _html} = live(conn, ~p"/source_control_repository")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#source_control_repository-#{repository.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/source_control_repository/#{repository}/edit")

      assert render(form_live) =~ "Edit repository"

      assert form_live
             |> form("#repository-form", repository: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#repository-form", repository: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/source_control_repository")

      html = render(index_live)
      assert html =~ "repository updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes repository in listing", %{conn: conn, repository: repository} do
      {:ok, index_live, _html} = live(conn, ~p"/source_control_repository")

      assert index_live
             |> element("#source_control_repository-#{repository.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#source_control_repository-#{repository.id}")
    end
  end

  describe "Show" do
    setup [:create_repository]

    test "displays repository", %{conn: conn, repository: repository} do
      {:ok, _show_live, html} = live(conn, ~p"/source_control_repository/#{repository}")

      assert html =~ "Show repository"
      assert html =~ repository.name
    end

    test "updates repository and returns to show", %{conn: conn, repository: repository} do
      {:ok, show_live, _html} = live(conn, ~p"/source_control_repository/#{repository}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(
                 conn,
                 ~p"/source_control_repository/#{repository}/edit?return_to=show"
               )

      assert render(form_live) =~ "Edit repository"

      assert form_live
             |> form("#repository-form", repository: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#repository-form", repository: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/source_control_repository/#{repository}")

      html = render(show_live)
      assert html =~ "repository updated successfully"
      assert html =~ "some updated name"
    end
  end
end
