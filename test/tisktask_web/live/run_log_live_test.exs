defmodule TisktaskWeb.RunLogLiveTest do
  use TisktaskWeb.ConnCase

  import Phoenix.LiveViewTest
  import Tisktask.TasksFixtures

  @create_attrs %{content: "some content"}
  @update_attrs %{content: "some updated content"}
  @invalid_attrs %{content: nil}
  defp create_run_log(_) do
    run_log = run_log_fixture()

    %{run_log: run_log}
  end

  describe "Index" do
    setup [:create_run_log]

    test "lists all task_run_logs", %{conn: conn, run_log: run_log} do
      {:ok, _index_live, html} = live(conn, ~p"/task_run_logs")

      assert html =~ "Listing Task run logs"
      assert html =~ run_log.content
    end

    test "saves new run_log", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/task_run_logs")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Run log")
               |> render_click()
               |> follow_redirect(conn, ~p"/task_run_logs/new")

      assert render(form_live) =~ "New Run log"

      assert form_live
             |> form("#run_log-form", run_log: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#run_log-form", run_log: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/task_run_logs")

      html = render(index_live)
      assert html =~ "Run log created successfully"
      assert html =~ "some content"
    end

    test "updates run_log in listing", %{conn: conn, run_log: run_log} do
      {:ok, index_live, _html} = live(conn, ~p"/task_run_logs")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#task_run_logs-#{run_log.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/task_run_logs/#{run_log}/edit")

      assert render(form_live) =~ "Edit Run log"

      assert form_live
             |> form("#run_log-form", run_log: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#run_log-form", run_log: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/task_run_logs")

      html = render(index_live)
      assert html =~ "Run log updated successfully"
      assert html =~ "some updated content"
    end

    test "deletes run_log in listing", %{conn: conn, run_log: run_log} do
      {:ok, index_live, _html} = live(conn, ~p"/task_run_logs")

      assert index_live |> element("#task_run_logs-#{run_log.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#task_run_logs-#{run_log.id}")
    end
  end

  describe "Show" do
    setup [:create_run_log]

    test "displays run_log", %{conn: conn, run_log: run_log} do
      {:ok, _show_live, html} = live(conn, ~p"/task_run_logs/#{run_log}")

      assert html =~ "Show Run log"
      assert html =~ run_log.content
    end

    test "updates run_log and returns to show", %{conn: conn, run_log: run_log} do
      {:ok, show_live, _html} = live(conn, ~p"/task_run_logs/#{run_log}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/task_run_logs/#{run_log}/edit?return_to=show")

      assert render(form_live) =~ "Edit Run log"

      assert form_live
             |> form("#run_log-form", run_log: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#run_log-form", run_log: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/task_run_logs/#{run_log}")

      html = render(show_live)
      assert html =~ "Run log updated successfully"
      assert html =~ "some updated content"
    end
  end
end
