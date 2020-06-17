defmodule DHT.Port do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def read(pin, sensor) do
    GenServer.call(__MODULE__, {:read, pin, sensor})
  end

  @impl true
  def init(_opts) do
    exec =
      Application.app_dir(:dht, "priv")
      |> Path.join("dht")

    port = Port.open({:spawn_executable, exec}, [{:packet, 2}, :binary, :use_stdio, :exit_status])

    {:ok, %{port: port}}
  end

  @impl true
  def handle_call({:read, pin, sensor}, from, state) do
    message = {:read, from, {pin, sensor}}

    send(state.port, {self(), {:command, :erlang.term_to_binary(message)}})
    {:noreply, state}
  end

  @impl true
  def handle_info({_, {:data, data}}, state) do
    {condition, result, from} = :erlang.binary_to_term(data)
    GenServer.reply(from, {condition, result})
    {:noreply, state}
  end
end
