defmodule TisktaskWeb.RunLiveTest do
  use TisktaskWeb.ConnCase

  import Phoenix.LiveViewTest

  @create_attrs %{}
  defp create_run(_) do
    run = insert(:task_run)

    %{run: run}
  end

  describe "Index" do
    setup [:create_run, :register_and_log_in_user]

    test "lists all tasks", %{conn: conn, run: _run} do
      {:ok, _index_live, html} = live(conn, ~p"/tasks")

      assert html =~ "Listing Task runs"
    end

    @tag :skip
    test "saves new run", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/tasks")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Run")
               |> render_click()
               |> follow_redirect(conn, ~p"/tasks/new")

      assert render(form_live) =~ "New Run"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#run-form", run: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/tasks")

      html = render(index_live)
      assert html =~ "Run created successfully"
      assert html =~ "some status"
    end
  end

  describe "Show" do
    setup [:create_run, :register_and_log_in_user]

    test "displays run", %{conn: conn, run: run} do
      {:ok, _show_live, html} = live(conn, ~p"/tasks/#{run}")

      assert html =~ "Show Run"
      assert html =~ to_string(run.status)
    end
  end
end
