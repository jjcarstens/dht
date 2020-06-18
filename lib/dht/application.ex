defmodule DHT.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: DHT.Supervisor]

    children = [
      DHT.Port,
      DHT.Telemetry,
      {Registry, keys: :unique, name: Pollers}
    ]

    Supervisor.start_link(children, opts)
  end
end
