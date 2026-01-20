defmodule TisktaskWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use TisktaskWeb, :html

  embed_templates "layouts/*"

  attr :current_scope, :any, default: nil
  attr :flash, :map, required: true
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open">
      <input id="sidebar-drawer" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content flex flex-col">
        <%!-- Mobile navbar --%>
        <div class="navbar lg:hidden bg-base-100 border-b border-base-300">
          <div class="flex-none">
            <label for="sidebar-drawer" class="btn btn-square btn-ghost drawer-button">
              <.icon name="hero-bars-3" class="size-5" />
            </label>
          </div>
          <div class="flex-1">
            <a href="/" class="flex items-center gap-2">
              <img src={~p"/images/logo.svg"} width="28" />
              <span class="font-semibold">Tisktask</span>
            </a>
          </div>
        </div>

        <%!-- Main content --%>
        <main class="flex-1 p-6">
          <div class="max-w-6xl mx-auto">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>

      <div class="drawer-side z-40">
        <label for="sidebar-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
        <aside class="bg-base-200 min-h-screen w-64 flex flex-col">
          <%!-- Logo --%>
          <div class="p-4 border-b border-base-300">
            <a href="/" class="flex items-center gap-3">
              <img src={~p"/images/logo.svg"} width="32" />
              <span class="font-bold text-lg">Tisktask</span>
            </a>
          </div>

          <%!-- Navigation --%>
          <nav class="flex-1 p-4">
            <ul class="menu menu-lg gap-1">
              <li>
                <.link navigate={~p"/tasks"} class="flex items-center gap-3">
                  <.icon name="hero-play-circle" class="size-5" />
                  <span>Tasks</span>
                </.link>
              </li>
              <li>
                <.link navigate={~p"/repositories"} class="flex items-center gap-3">
                  <.icon name="hero-folder" class="size-5" />
                  <span>Repositories</span>
                </.link>
              </li>
            </ul>
          </nav>

          <%!-- Footer with user info and theme toggle --%>
          <div class="p-4 border-t border-base-300">
            <div class="flex items-center justify-between mb-4">
              <span class="text-sm text-base-content/70">Theme</span>
              <.theme_toggle />
            </div>

            <%= if @current_scope do %>
              <div class="menu menu-sm gap-1">
                <li class="menu-title text-xs truncate" title={@current_scope.user.email}>
                  {@current_scope.user.email}
                </li>
                <li>
                  <.link navigate={~p"/users/settings"}>
                    <.icon name="hero-cog-6-tooth" class="size-4" /> Settings
                  </.link>
                </li>
                <li>
                  <.link href={~p"/users/log-out"} method="delete">
                    <.icon name="hero-arrow-right-on-rectangle" class="size-4" /> Log out
                  </.link>
                </li>
              </div>
            <% else %>
              <div class="menu menu-sm gap-1">
                <li>
                  <.link navigate={~p"/users/log-in"}>
                    <.icon name="hero-arrow-left-on-rectangle" class="size-4" /> Log in
                  </.link>
                </li>
                <li>
                  <.link navigate={~p"/users/register"}>
                    <.icon name="hero-user-plus" class="size-4" /> Register
                  </.link>
                </li>
              </div>
            <% end %>
          </div>
        </aside>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-[33%] h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-[33%] [[data-theme=dark]_&]:left-[66%] transition-[left]" />

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})} class="flex p-2">
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})} class="flex p-2">
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})} class="flex p-2">
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
