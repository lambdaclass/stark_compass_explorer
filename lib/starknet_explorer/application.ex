defmodule StarknetExplorer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  import StarknetExplorer.Utils
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Start the Telemetry supervisor
        StarknetExplorerWeb.Telemetry,
        # Start the Ecto repository
        StarknetExplorer.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: StarknetExplorer.PubSub},
        # Start Finch
        {Finch, name: StarknetExplorer.Finch},
        # Start the Endpoint (http/https)
        StarknetExplorerWeb.Endpoint
        # Start a worker by calling: StarknetExplorer.Worker.start_link(arg)
        # {StarknetExplorer.Worker, arg}
      ] ++
        if_prod do
          # TODO: Uncomment when it's ready
          # [StarknetExplorer.BlockFetcher]
          []
        else
          []
        end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StarknetExplorer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StarknetExplorerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
