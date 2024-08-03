defmodule VExchange.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []
    Logger.add_backend(Sentry.LoggerBackend)

    children = [
      # Start the Telemetry supervisor
      VExchangeWeb.Telemetry,
      # Start the RPC server
      {Fly.RPC, []},
      # Start the Ecto repository
      VExchange.Repo.Local,
      # Start the supervisor for LSN tracking
      {Fly.Postgres.LSN.Supervisor, repo: VExchange.Repo.Local},
      # Start the PubSub system
      {Phoenix.PubSub, name: VExchange.PubSub},
      # Start Finch
      {Finch, name: VExchange.Finch},
      # Start the Endpoint (http/https)
      VExchangeWeb.Endpoint,
      # Start a worker by calling: VExchange.Worker.start_link(arg)
      # {VExchange.Worker, arg}
      {Cluster.Supervisor, [topologies, [name: VExchange.ClusterSupervisor]]},
      {Oban, Application.fetch_env!(:v_exchange, Oban)},
      VExchange.QueryCache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VExchange.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VExchangeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
