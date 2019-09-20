defmodule DHT do
  use GenServer

  def start_link(pin_num \\ 17, source \\ :circuits_gpio) do
    GenServer.start_link(__MODULE__, {pin_num, source}, name: __MODULE__)
  end

  def init({pin_num, source}) do
    case source do
      :circuits_gpio ->
        {:ok, pin} = Circuits.GPIO.open(pin_num, :input)
        Circuits.GPIO.set_interrupts(pin, :both)
        {:ok, %{pin: pin, data: []}}

      :pigpiox ->
        Pigpiox.GPIO.set_mode(pin_num, :input)
        {:ok, watch_pid} = Pigpiox.GPIO.watch(pin_num)
        {:ok, %{pin: pin_num, watch_pid: watch_pid, data: []}}

      unknown ->
        {:stop, "Don't know how to use source #{inspect(unknown)}"}
    end
  end

  def print(list, acc \\ <<>>)

  def print([{time, _val} = val | rem], acc) do
    IO.puts("#{inspect(val)}")
    unless rem == [] do
      [{next_time, _} | _rem] = rem
      timing = (next_time - time) |> Kernel.div(1000) |> round()
      bit = if (timing - 50) in 26..28, do: 0, else: 1
      IO.puts("\t\t|-- #{timing} us")
      IO.puts("\t\t|-- #{bit}")
      print(rem, acc <> <<bit>>)
    end
    inspect(acc)
  end

  def print([], acc), do: inspect(acc)

  def read(server \\ __MODULE__), do: GenServer.call(server, :read)

  def restart(server \\ __MODULE__) do
    GenServer.stop(server)
    start_link()
  end

  def refresh(server \\ __MODULE__) do
    GenServer.cast(server, :refresh)
  end

  def handle_call(:read, _from, state) do
    # Sort them all by timestamp so they are in order
    # data = Enum.sort_by(state.data, &elem(&1, 0))
    data = Enum.reverse(state.data)

    {:reply, %{state | data: data}, state}
  end

  def handle_cast(:refresh, %{pin: pin} = state) when is_number(pin) do
    Pigpiox.GPIO.set_mode(pin, :output)

    # Datasheet says minimum of 1ms, but can allow up to 10ms
    # for the trigger. This is here to alter more easily
    trigger_time = Application.get_env(:dht, :trigger_time, 1)

    Pigpiox.GPIO.write(pin, 0)
    # 1 ms trigger
    :timer.sleep(trigger_time)
    Pigpiox.GPIO.write(pin, 1)
    Pigpiox.GPIO.set_mode(pin, :input)

    Pigpiox.GPIO.watch(pin)

    # Circuits.GPIO.set_interrupts(pin, :both)
    {:noreply, %{state | data: []}}
  end

  def handle_cast(:refresh, %{pin: pin} = state) do
    Circuits.GPIO.set_direction(pin, :output)

    # Datasheet says minimum of 1ms, but can allow up to 10ms
    # for the trigger. This is here to alter more easily
    trigger_time = Application.get_env(:dht, :trigger_time, 1)

    Circuits.GPIO.write(pin, 0)
    # 1 ms trigger
    :timer.sleep(trigger_time)
    Circuits.GPIO.write(pin, 1)
    Circuits.GPIO.set_direction(pin, :input)

    # Circuits.GPIO.set_interrupts(pin, :both)
    {:noreply, %{state | data: []}}
  end

  def handle_info({:circuits_gpio, _pin, time, val} = msg, %{data: data} = state) do
    IO.inspect(msg)
    {:noreply, %{state | data: [{time, val} | data]}}
  end

  def handle_info({:gpio_leveL_change, _gpio, val} = msg, %{data: data} = state) do
    IO.inspect(msg)
    {:noreply, %{state | data: [{System.monotonic_time(:nanosecond), val} | data]}}
  end
end
