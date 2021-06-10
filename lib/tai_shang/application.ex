defmodule TaiShang.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      TaiShang.Repo,
      # Start the Telemetry supervisor
      TaiShangWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: TaiShang.PubSub},
      # Start the Endpoint (http/https)
      TaiShangWeb.Endpoint
      # Start a worker by calling: TaiShang.Worker.start_link(arg)
      # {TaiShang.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TaiShang.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TaiShangWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
