defmodule TisktaskWeb.Router do
  use TisktaskWeb, :router

  import TisktaskWeb.UserAuth

  import Oban.Web.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {TisktaskWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", TisktaskWeb do
    pipe_through(:browser)

    oban_dashboard("/oban")

    get("/", PageController, :home)
    live("/tasks", RunLive.Index, :index)
    live("/tasks/new", RunLive.Form, :new)
    live("/tasks/:id", RunLive.Show, :show)

    live("/repositories", RepositoryLive.Index, :index)
    live("/repositories/new", RepositoryLive.Form, :new)
    live("/repositories/:id", RepositoryLive.Show, :show)
    live("/repositories/:id/edit", RepositoryLive.Form, :edit)
  end

  scope "/api", TisktaskWeb do
    pipe_through(:api)

    resources("/:originator/events", SourceControl.EventController)
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:tisktask, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: TisktaskWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes

  scope "/", TisktaskWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{TisktaskWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", TisktaskWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{TisktaskWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
