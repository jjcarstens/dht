defmodule DHT.Application do
  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: DHT.Supervisor]
    children = [DHT.Port]

    Supervisor.start_link(children, opts)
  end
end
