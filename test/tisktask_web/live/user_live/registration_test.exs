defmodule TisktaskWeb.UserLive.RegistrationTest do
  use TisktaskWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Tisktask.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
    end
  end

  describe "register user" do
    test "creates account with email and password and redirects to login", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()
      password = valid_user_password()

      {:ok, _lv, html} =
        lv
        |> form("#registration_form",
          user: %{
            "email" => email,
            "password" => password,
            "password_confirmation" => password
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "Account created successfully"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{"email" => user.email, "password" => valid_user_password()}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end

    test "renders errors for password too short", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> form("#registration_form",
          user: %{"email" => unique_user_email(), "password" => "short"}
        )
        |> render_submit()

      assert result =~ "should be at least 12 character"
    end

    test "renders errors for password confirmation mismatch", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> form("#registration_form",
          user: %{
            "email" => unique_user_email(),
            "password" => valid_user_password(),
            "password_confirmation" => "different_password"
          }
        )
        |> render_submit()

      assert result =~ "does not match password"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Log in")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert login_html =~ "Log in"
    end
  end
end
