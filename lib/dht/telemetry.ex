defmodule DHT.Telemetry do
  @moduledoc false
  use DynamicSupervisor

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_polling(pin, sensor, period \\ 2) do
    opts = [
      measurements: [{__MODULE__, :poll_read, [pin, sensor]}],
      period: :timer.seconds(period),
      name: via_name(pin, sensor)
    ]
    spec = :telemetry_poller.child_spec(opts)

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_polling(pin, sensor) do
    via_name(pin, sensor)
    |> GenServer.whereis()
    |> case do
      nil -> {:error, :not_found}
      poller -> DynamicSupervisor.terminate_child(__MODULE__, poller)
    end
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def poll_read(pin, sensor) do
    meta = %{pin: pin, sensor: sensor}

    case DHT.read(pin, sensor) do
      {:ok, reading} ->
        :telemetry.execute([:dht, :read], reading, meta)
      {:error, err} ->
        :telemetry.execute([:dht, :failure], %{error: err}, meta)
    end
  end

  defp via_name(pin, sensor) do
    {:via, Registry, {Pollers, {pin, sensor}}}
  end
end
