defmodule TisktaskWeb.RunLiveTest do
  use TisktaskWeb.ConnCase

  import Phoenix.LiveViewTest

  @create_attrs %{status: "some status"}
  @update_attrs %{status: "some updated status"}
  @invalid_attrs %{status: nil}
  defp create_run(_) do
    run = insert(:task_run)

    %{run: run}
  end

  describe "Index" do
    setup [:create_run]

    test "lists all tasks", %{conn: conn, run: run} do
      {:ok, _index_live, html} = live(conn, ~p"/tasks")

      assert html =~ "Listing Task runs"
      assert html =~ run.status
    end

    test "saves new run", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/tasks")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Run")
               |> render_click()
               |> follow_redirect(conn, ~p"/tasks/new")

      assert render(form_live) =~ "New Run"

      assert form_live
             |> form("#run-form", run: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#run-form", run: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/tasks")

      html = render(index_live)
      assert html =~ "Run created successfully"
      assert html =~ "some status"
    end

    test "updates run in listing", %{conn: conn, run: run} do
      {:ok, index_live, _html} = live(conn, ~p"/tasks")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#tasks-#{run.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/tasks/#{run}/edit")

      assert render(form_live) =~ "Edit Run"

      assert form_live
             |> form("#run-form", run: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#run-form", run: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/tasks")

      html = render(index_live)
      assert html =~ "Run updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes run in listing", %{conn: conn, run: run} do
      {:ok, index_live, _html} = live(conn, ~p"/tasks")

      assert index_live |> element("#tasks-#{run.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#tasks-#{run.id}")
    end
  end

  describe "Show" do
    setup [:create_run]

    test "displays run", %{conn: conn, run: run} do
      {:ok, _show_live, html} = live(conn, ~p"/tasks/#{run}")

      assert html =~ "Show Run"
      assert html =~ run.status
    end

    test "updates run and returns to show", %{conn: conn, run: run} do
      {:ok, show_live, _html} = live(conn, ~p"/tasks/#{run}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/tasks/#{run}/edit?return_to=show")

      assert render(form_live) =~ "Edit Run"

      assert form_live
             |> form("#run-form", run: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#run-form", run: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/tasks/#{run}")

      html = render(show_live)
      assert html =~ "Run updated successfully"
      assert html =~ "some updated status"
    end
  end
end
