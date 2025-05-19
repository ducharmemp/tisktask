defmodule Tisktask.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Oban.Telemetry.attach_default_logger()

    children = [
      TisktaskWeb.Telemetry,
      Tisktask.Repo,
      {DNSCluster, query: Application.get_env(:tisktask, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:tisktask, Oban)},
      {Phoenix.PubSub, name: Tisktask.PubSub},
      {Task.Supervisor, name: Tisktask.TaskSupervisor},
      # Start a worker by calling: Tisktask.Worker.start_link(arg)
      # {Tisktask.Worker, arg},
      # Start to serve requests, typically the last entry
      TisktaskWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tisktask.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TisktaskWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
